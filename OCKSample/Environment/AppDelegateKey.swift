//
//  AppDelegateKey.swift
//  OCKSample
//
//  Created by Corey Baker on 9/2/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import SwiftUI

struct AppDelegateKey: EnvironmentKey {
    static var defaultValue: AppDelegate?
}

extension EnvironmentValues {
    var appDelegate: AppDelegateKey.Value {
        get {
            return self[AppDelegateKey.self]
        }
        set {
            AppDelegateKey.defaultValue = newValue
            self[AppDelegateKey.self] = newValue
        }
    }
}
