//
//  Login.swift
//  OCKWatchSample Extension
//
//  Created by Corey Baker on 12/10/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
//

import SwiftUI
import CareKit

class LoginViewModel: ObservableObject {
    // swiftlint:disable:next force_cast
    private let watchDelegate = WKExtension.shared().delegate as! ExtensionDelegate

    var syncWithCloud: Bool {
        return watchDelegate.syncWithCloud
    }

    @Published var isLoggedIn = false

    init() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(loginChanged(_:)),
                                               name: Notification.Name(rawValue: Constants.userLoggedIn),
                                               object: nil)
    }

    @objc private func loginChanged(_ notification: Notification) {
        isLoggedIn = true
    }

}
