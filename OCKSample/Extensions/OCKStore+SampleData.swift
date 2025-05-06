//
//  OCKStore+SampleData.swift
//  OCKSample
//
//  Created by Corey Baker on 5/6/25.
//  Copyright © 2025 Network Reconnaissance Lab. All rights reserved.
//

import CareKitStore
import Foundation
import os.log

extension OCKStore {
	func populateSampleOutcomes(
		startDate: Date
	) async throws {

		// Prepare previous samples.
		let yesterDay = Calendar.current.date(
			byAdding: .day,
			value: -1,
			to: Date()
		)!.endOfDay
		guard yesterDay > startDate else {
			throw AppError.errorString("Start date must be before last night")
		}
		let dateInterval = DateInterval(
			start: startDate,
			end: yesterDay
		)
		let eventQuery = OCKEventQuery(
			dateInterval: dateInterval
		)
		let pastEvents = try await fetchEvents(query: eventQuery)
		let pastOutcomes = pastEvents.compactMap { event -> OCKOutcome? in

			let initialRandomDate = randomDate(
				event.scheduleEvent.start,
				end: event.scheduleEvent.end
			)

			switch event.task.id {
			case TaskID.doxylamine, TaskID.kegels, TaskID.stretch:
				let randomBool: Bool = .random()
				guard randomBool else { return nil }
				let outcomeValue = createOutcomeValue(
					randomBool,
					createdDate: initialRandomDate
				)

				let outcome = addValueToOutcome(
					[outcomeValue],
					for: event
				)
				return outcome
			case TaskID.nausea:
				// multiple random bools
				let outcomeValues = (0...3).compactMap { _ -> OCKOutcomeValue? in
					let randomBool: Bool = .random()
					guard randomBool else { return nil }
					let randomDate = randomDate(
						event.scheduleEvent.start,
						end: event.scheduleEvent.end
					)
					let outcomeValue = createOutcomeValue(
						randomBool,
						createdDate: randomDate
					)

					return outcomeValue
				}

				let outcome = addValueToOutcome(
					outcomeValues,
					for: event
				)
				return outcome

			default:
				return nil
			}
		}

		do {
			let savedOutcomes = try await addOutcomes(pastOutcomes)
			Logger.ockStore.info("Added sample \(savedOutcomes.count) outcomes to OCKStore!")
		} catch {
			Logger.ockStore.error("Error adding sample outcomes: \(error)")
		}
	}

	private func createOutcomeValue(
		_ value: OCKOutcomeValueUnderlyingType,
		createdDate: Date
	) -> OCKOutcomeValue {
		var outcomeValue = OCKOutcomeValue(
			value
		)
		outcomeValue.createdDate = createdDate
		return outcomeValue
	}

	private func addValueToOutcome(
		_ values: [OCKOutcomeValue],
		for event: OCKEvent<OCKTask, OCKOutcome>
	) -> OCKOutcome? {

		guard !values.isEmpty else {
			// Act like nothing was submitted.
			return nil
		}

		guard var outcome = event.outcome else {
			// Event doesn't have an outcome, need to
			// create a new one that exists in the past.
			var newOutcome = OCKOutcome(
				taskUUID: event.task.uuid,
				taskOccurrenceIndex: event.scheduleEvent.occurrence,
				values: values
			)

			let effectiveDate = newOutcome
				.sortedOutcomeValuesByRecency()
				.values
				.last?.createdDate ?? event.scheduleEvent.start

			newOutcome.effectiveDate = effectiveDate
			return newOutcome
		}

		outcome.values.append(contentsOf: values)
		let effectiveDate = outcome
			.sortedOutcomeValuesByRecency()
			.values
			.last?.createdDate ?? event.scheduleEvent.start
		outcome.effectiveDate = effectiveDate
		return outcome
	}

	private func randomDate(_ startDate: Date, end endDate: Date) -> Date {
		let timeIntervalRange = startDate.timeIntervalSince1970..<endDate.timeIntervalSince1970
		let randomTimeInterval = TimeInterval.random(in: timeIntervalRange)
		let randomDate = Date(timeIntervalSince1970: randomTimeInterval)
		return randomDate
	}
}
