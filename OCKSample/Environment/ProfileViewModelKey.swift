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

    static var defaultValue: ProfileViewModel {
        // swiftlint:disable:next force_cast
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.profileViewModel
    }
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
