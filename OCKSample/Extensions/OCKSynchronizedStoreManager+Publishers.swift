//
//  OCKSynchronizedStoreManager+Publishers.swift
//  OCKSample
//
//  Created by Corey Baker on 1/5/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import CareKit
import CareKitStore
import Combine
import Foundation

extension OCKSynchronizedStoreManager {

    // MARK: Patients

    func publisher(forPatient patient: OCKAnyPatient,
                   categories: [OCKStoreNotificationCategory]) -> AnyPublisher<OCKAnyPatient, Never> {
        let presentValuePublisher = Future<OCKAnyPatient, Never>({ completion in
            self.store.fetchAnyPatient(withID: patient.id) { result in
                completion(.success((try? result.get()) ?? patient))
            }
        })

        return AnyPublisher(notificationPublisher
            .compactMap { $0 as? OCKPatientNotification }
            .filter { $0.patient.id == patient.id && categories.contains($0.category) }
            .map { $0.patient }
            .prepend(presentValuePublisher))
    }

    // MARK: CarePlans

    func publisher(forCarePlan plan: OCKAnyCarePlan,
                   categories: [OCKStoreNotificationCategory]) -> AnyPublisher<OCKAnyCarePlan, Never> {
        let presentValuePublisher = Future<OCKAnyCarePlan, Never> { completion in
            self.store.fetchAnyCarePlan(withID: plan.id) { result in
                completion(.success((try? result.get()) ?? plan))
            }
        }

        return AnyPublisher(notificationPublisher
            .compactMap { $0 as? OCKCarePlanNotification }
            .filter { $0.carePlan.id == plan.id && categories.contains($0.category) }
            .map { $0.carePlan }
            .prepend(presentValuePublisher))
    }

    // MARK: Tasks

    func publisherForTasks(categories: [OCKStoreNotificationCategory]) -> AnyPublisher<OCKTaskNotification, Never> {
        notificationPublisher
            .compactMap { $0 as? OCKTaskNotification }
            .filter { categories.contains($0.category) }
            .eraseToAnyPublisher()
    }

    func publisher(forTask task: OCKAnyTask,
                   categories: [OCKStoreNotificationCategory]) -> AnyPublisher<OCKTaskNotification, Never> {
        publisherForTasks(categories: categories)
            .filter { $0.task.id == task.id }
            .eraseToAnyPublisher()
    }

    func publisher(forEventsBelongingToTask task: OCKAnyTask,
                   categories: [OCKStoreNotificationCategory]) -> AnyPublisher<OCKAnyEvent, Never> {
        return AnyPublisher(notificationPublisher
            .compactMap { $0 as? OCKOutcomeNotification }
            .filter { $0.outcome.belongs(to: task) && categories.contains($0.category) }
            .map { self.makeEvent(task: task, outcome: $0.outcome, keepOutcome: $0.category != .delete) })
    }

    func publisher(forEventsBelongingToTask task: OCKAnyTask, query: OCKEventQuery,
                   categories: [OCKStoreNotificationCategory]) -> AnyPublisher<OCKAnyEvent, Never> {

        let validIndices = task.schedule.events(from: query.dateInterval.start, to: query.dateInterval.end)
            .map { $0.occurrence }

        return publisher(forEventsBelongingToTask: task, categories: categories)
            .filter { validIndices.contains($0.scheduleEvent.occurrence) }
            .eraseToAnyPublisher()
    }

    private func makeEvent(task: OCKAnyTask, outcome: OCKAnyOutcome, keepOutcome: Bool) -> OCKAnyEvent {
        guard let scheduleEvent = task.schedule.event(forOccurrenceIndex: outcome.taskOccurrenceIndex) else {
            fatalError("""
                The outcome had an index of \(outcome.taskOccurrenceIndex),
                but the task's schedule does not have that many events.
            """)
        }
        return OCKAnyEvent(task: task, outcome: keepOutcome ? outcome : nil, scheduleEvent: scheduleEvent)
    }

    // MARK: Events

    func publisher(forEvent event: OCKAnyEvent,
                   categories: [OCKStoreNotificationCategory]) -> AnyPublisher<OCKAnyEvent, Never> {
        let presentValuePublisher = Future<OCKAnyEvent, Never>({ completion in
            self.store.fetchAnyEvent(forTask: event.task,
                                     occurrence: event.scheduleEvent.occurrence,
                                     callbackQueue: .main) { result in
                completion(.success((try? result.get()) ?? event))
            }
        })

        return AnyPublisher(notificationPublisher
            .compactMap { $0 as? OCKOutcomeNotification }
            .filter { self.outcomeMatchesEvent(outcome: $0.outcome, event: event) }
            .map { self.makeEvent(task: event.task,
                                  outcome: $0.outcome,
                                  keepOutcome: $0.category != .delete) }
            .prepend(presentValuePublisher))
    }

    private func outcomeMatchesEvent(outcome: OCKAnyOutcome, event: OCKAnyEvent) -> Bool {
        outcome.belongs(to: event.task) && event.scheduleEvent.occurrence == outcome.taskOccurrenceIndex
    }
}
