//
//  OCKOutcome.swift
//  OCKSample
//
//  Created by Corey Baker on 1/5/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import CareKitStore

extension OCKOutcome {
    func sortedOutcomeValuesByRecency() -> Self {
        guard !self.values.isEmpty else { return self }
        var newOutcome = self
        let sortedValues = newOutcome.values.sorted {
            $0.createdDate > $1.createdDate
        }

        newOutcome.values = sortedValues
        return newOutcome
    }

    func sortedOutcomeValues() -> Self {
        guard !self.values.isEmpty else { return self }
        var newOutcome = self
        let sortedValues = newOutcome.values.sorted {
            if let value0 = $0.dateValue,
               let value1 = $1.dateValue {
                return value0 > value1
            } else if let value0 = $0.integerValue,
                      let value1 = $1.integerValue {
                return value0 > value1
            } else if let value0 = $0.doubleValue,
                      let value1 = $1.doubleValue {
                return value0 > value1
            } else {
                return false
            }
        }

        newOutcome.values = sortedValues
        return newOutcome
    }

    func updateDateWithComponents(_ date: Date = Date()) -> Self {
        guard !self.values.isEmpty else { return self }
        var newOutcome = self
        let updatedValues = values.compactMap { value -> OCKOutcomeValue? in
            guard let date = value.dateValue else {
                return value
            }
            let components = Calendar.current.dateComponents([.hour, .minute], from: date)
            guard let hour = components.hour,
                let minute = components.minute,
                let updatedDate = Calendar.current.date(bySettingHour: hour,
                                                        minute: minute,
                                                        second: 0, of: date) else {
                    return value
                }
            var updatedValue = value
            updatedValue.value = updatedDate
            return updatedValue
        }
        newOutcome.values = updatedValues
        return newOutcome
    }
}
