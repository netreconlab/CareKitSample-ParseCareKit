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

struct StoreManagerKey: EnvironmentKey {

    static var defaultValue: OCKSynchronizedStoreManager? {
        // swiftlint:disable:next force_cast
        let extensionDelegate = UIApplication.shared.delegate as! AppDelegate
        return extensionDelegate.storeManager
    }
}

extension EnvironmentValues {

    var storeManager: OCKSynchronizedStoreManager? {
        get {
            self[StoreManagerKey.self]
        }

        set {
            self[StoreManagerKey.self] = newValue
        }
    }
}
