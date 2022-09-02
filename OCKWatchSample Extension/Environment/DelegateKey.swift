//
//  DelegateKey.swift
//  OCKWatchSample
//
//  Created by Corey Baker on 9/2/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import SwiftUI

struct DelegateKey: EnvironmentKey {
    static var defaultValue: ApplicationDelegate?
}

extension EnvironmentValues {
    var appDelegate: DelegateKey.Value {
        get {
            return self[DelegateKey.self]
        }
        set {
            DelegateKey.defaultValue = newValue
            self[DelegateKey.self] = newValue
        }
    }
}
