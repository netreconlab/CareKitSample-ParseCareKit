//
//  StoreManagerKey.swift
//  OCKSample
//
//  Created by Corey Baker on 10/16/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import SwiftUI
import CareKit
import CareKitStore

struct StoreManagerKey: EnvironmentKey {
    static var defaultValue = OCKSynchronizedStoreManager(wrapping: OCKStore(name: Constants.noCareStoreName,
                                                                             type: .inMemory))
}

extension EnvironmentValues {

    var storeManager: OCKSynchronizedStoreManager {
        get {
            self[StoreManagerKey.self]
        }

        set {
            self[StoreManagerKey.self] = newValue
        }
    }
}
