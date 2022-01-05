//
//  OCKHealthKitPassthroughStore+Default.swift
//  OCKSample
//
//  Created by Corey Baker on 1/5/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import CareKitStore
import HealthKit
import os.log

extension OCKHealthKitPassthroughStore {

    func addTasksIfNotPresent(_ tasks: [OCKHealthKitTask]) {
        let tasksToAdd = tasks
        let taskIdsToAdd = tasksToAdd.compactMap { $0.id }

        // Prepare query to see if tasks are already added
        var query = OCKTaskQuery(for: Date())
        query.ids = taskIdsToAdd

        fetchTasks(query: query) { result in

            if case let .success(foundTasks) = result {

                var tasksNotInStore = [OCKHealthKitTask]()

                // Check results to see if there's a missing task
                tasksToAdd.forEach { potentialTask in
                    if foundTasks.first(where: { $0.id == potentialTask.id }) == nil {
                        tasksNotInStore.append(potentialTask)
                    }
                }

                // Only add if there's a new task
                if tasksNotInStore.count > 0 {
                    self.addTasks(tasksNotInStore) { result in
                        switch result {
                        case .success: Logger.appDelegate.info("Added tasks into HealthKitPassthroughStore!")
                        case .failure(let error): Logger.appDelegate.error("\(error.localizedDescription)")
                        }
                    }
                }
            }
        }
    }

    func populateSampleData() {

        let schedule = OCKSchedule.dailyAtTime(
            hour: 8, minutes: 0, start: Date(), end: nil, text: nil,
            duration: .hours(12), targetValues: [OCKOutcomeValue(2000.0, units: "Steps")])

        var steps = OCKHealthKitTask(
            id: TaskID.steps,
            title: "Steps",
            carePlanUUID: nil,
            schedule: schedule,
            healthKitLinkage: OCKHealthKitLinkage(
                quantityIdentifier: .stepCount,
                quantityType: .cumulative,
                unit: .count()))
        steps.asset = "figure.walk"
        addTasksIfNotPresent([steps])
    }
}
