//
//  OCKOutcomeValue+Identifiable.swift
//  OCKSample
//
//  Created by Corey Baker on 1/5/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import CareKitStore

extension OCKOutcomeValue: Identifiable {
    public var id: String {
        if let kind = kind {
            return "\(kind)_\(value)_\(createdDate)"
        } else {
            return "\(value)_\(createdDate)"
        }
    }
}
