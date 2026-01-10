//
//  Mutex.swift
//  OCKSample
//
//  Created by Corey Baker on 1/7/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import Synchronization

extension Mutex where Value: Sendable {

    func value() -> Value {
        return withLock { $0 }
    }

    func setValue(_ value: Value) {
        withLock { $0 = value }
    }
}
