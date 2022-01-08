//
//  OCKAnyEvent+CustomStringConvertable.swift
//  OCKSample
//
//  Created by Corey Baker on 1/5/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import CareKitStore

extension OCKAnyEvent: CustomStringConvertible {

    public var description: String {
        guard let task = self.task as? OCKTask,
            let encodedTask = try? JSONEncoder().encode(task),
            let stringTask = String(data: encodedTask, encoding: .utf8),
            let outcome = self.outcome as? OCKOutcome,
            let encodedOutcome = try? JSONEncoder().encode(outcome),
            let stringOutcome = String(data: encodedOutcome, encoding: .utf8) else {
            return ""
        }
        return stringTask + stringOutcome
    }
}

extension OCKAnyEvent: Comparable {
    public static func == (lhs: OCKAnyEvent, rhs: OCKAnyEvent) -> Bool {
        lhs.id == rhs.id
    }

    public static func < (lhs: OCKAnyEvent, rhs: OCKAnyEvent) -> Bool {
        lhs.scheduleEvent < rhs.scheduleEvent
    }

    /// Sort outcome values by descending updated/created date
    func sortedOutcomeValuesByRecency() -> OCKAnyEvent {
        guard
            var newOutcome = outcome,
            !newOutcome.values.isEmpty else { return self }

        let sortedValues = newOutcome.values.sorted {
            $0.createdDate > $1.createdDate
        }

        newOutcome.values = sortedValues
        return OCKAnyEvent(task: task, outcome: newOutcome, scheduleEvent: scheduleEvent)
    }

    func prependKindToValue() -> OCKAnyEvent {
        guard
            var newOutcome = outcome,
            !newOutcome.values.isEmpty else { return self }

        let prependedValues = newOutcome.values.map { originalValue -> OCKOutcomeValue in
            if let kind = originalValue.kind,
               let type = kind.split(separator: ".").last {
                var newValue = originalValue
                newValue.value = "\(type): \(newValue.value)"
                return newValue
            } else {
                return originalValue
            }
        }

        newOutcome.values = prependedValues
        return OCKAnyEvent(task: task, outcome: newOutcome, scheduleEvent: scheduleEvent)
    }
}
