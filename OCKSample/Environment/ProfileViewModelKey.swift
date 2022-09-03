//
//  ProfileViewModelKey.swift
//  OCKSample
//
//  Created by Corey Baker on 1/7/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import SwiftUI

struct ProfileViewModelKey: EnvironmentKey {

    static var defaultValue = ProfileViewModel()
}

extension EnvironmentValues {

    var userProfileViewModel: ProfileViewModel {
        get {
            self[ProfileViewModelKey.self]
        }

        set {
            self[ProfileViewModelKey.self] = newValue
        }
    }
}
