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
import Synchronization

struct StoreCoordinatorKey: EnvironmentKey {
	static var defaultValue: OCKStoreCoordinator {
		get {
			return _defaultValue.value()
		}
		set {
			_defaultValue.setValue(newValue)
		}
	}

	static private let _defaultValue = Mutex<OCKStoreCoordinator>(.init())
}

extension EnvironmentValues {

    var storeCoordinator: OCKStoreCoordinator {
        get {
            self[StoreCoordinatorKey.self]
        }

        set {
			StoreCoordinatorKey.defaultValue = newValue
            self[StoreCoordinatorKey.self] = newValue
        }
    }
}
