//
//  StoreCoordinatorKey.swift
//  OCKSample
//
//  Created by Corey Baker on 10/16/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import SwiftUI
import CareKit
import CareKitStore

struct StoreCoordinatorKey: EnvironmentKey {
    static var defaultValue = OCKStoreCoordinator()
}

extension EnvironmentValues {

    var storeCoordinator: OCKStoreCoordinator {
        get {
            self[StoreCoordinatorKey.self]
        }

        set {
            self[StoreCoordinatorKey.self] = newValue
        }
    }
}
