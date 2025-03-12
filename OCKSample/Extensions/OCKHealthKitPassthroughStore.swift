//
//  OCKHealthKitPassthroughStore.swift
//  OCKSample
//
//  Created by Corey Baker on 1/5/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import CareKitEssentials
import CareKitStore
import HealthKit
import os.log

extension OCKHealthKitPassthroughStore {

    func populateSampleData() async throws {

        let countUnit = HKUnit.count()
        let stepTargetValue = OCKOutcomeValue(
            2000.0,
            units: countUnit.unitString
        )
        let stepTargetValues = [ stepTargetValue ]
        let stepSchedule = OCKSchedule.dailyAtTime(
            hour: 8,
            minutes: 0,
            start: Date(),
            end: nil,
            text: nil,
            duration: .allDay,
            targetValues: stepTargetValues
        )
        var steps = OCKHealthKitTask(
            id: TaskID.steps,
            title: String(localized: "STEPS"),
            carePlanUUID: nil,
            schedule: stepSchedule,
            healthKitLinkage: OCKHealthKitLinkage(
                quantityIdentifier: .stepCount,
                quantityType: .cumulative,
                unit: countUnit
            )
        )
        steps.asset = "figure.walk"

        let ovulationTestResultSchedule = OCKSchedule.dailyAtTime(
            hour: 8,
            minutes: 0,
            start: Date(),
            end: nil,
            text: nil,
            duration: .allDay,
            targetValues: []
        )
        var ovulationTestResult = OCKHealthKitTask(
            id: TaskID.ovulationTestResult,
            title: String(localized: "OVULATION_TEST_RESULT"),
            carePlanUUID: nil,
            schedule: ovulationTestResultSchedule,
            healthKitLinkage: OCKHealthKitLinkage(
                categoryIdentifier: .ovulationTestResult
            )
        )
        ovulationTestResult.asset = "circle.dotted"
        let tasks = [ steps, ovulationTestResult ]

        _ = try await addTasksIfNotPresent(tasks)

    }
}
