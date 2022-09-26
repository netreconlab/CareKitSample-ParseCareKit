//
//  Login.swift
//  OCKWatchSample Extension
//
//  Created by Corey Baker on 12/10/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
//

import SwiftUI
import CareKit
import ParseSwift
import os.log

class LoginViewModel: ObservableObject {
    // MARK: Public read, private write properties
    @Published private(set) var isLoggedOut = true

    init() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(userLoggedIn(_:)),
                                               name: Notification.Name(rawValue: Constants.userLoggedIn),
                                               object: nil)
        self.checkStatus()
    }

    // MARK: Helpers (private)
    @objc private func userLoggedIn(_ notification: Notification) {
        self.checkStatus()
    }

    private func checkStatus() {
        DispatchQueue.main.async {
            let isLoggedOut = self.isLoggedOut
            if User.current != nil && isLoggedOut {
                self.isLoggedOut = false
            } else if User.current == nil && !isLoggedOut {
                self.isLoggedOut = true
            }
        }
    }

    // MARK: Helpers (public)
    @MainActor
    class func loginFromiPhoneMessage(_ message: [String: Any]) async {
        guard let sessionToken = message[Constants.parseUserSessionTokenKey] as? String else {
            Logger.login.error("Error: data missing in iPhone message")
            return
        }

        do {
            let user = try await User().become(sessionToken: sessionToken)
            Logger.login.info("Parse login successful \(user, privacy: .private)")
            try Utility.setupRemoteAfterLogin()
            guard let watchDelegate = AppDelegateKey.defaultValue else {
                Logger.login.error("ApplicationDelegate should not be nil")
                return
            }
            watchDelegate.store.synchronize { error in
                NotificationCenter.default.post(.init(name: Notification.Name(rawValue: Constants.userLoggedIn)))
                let errorString = error?.localizedDescription ?? "Successful sync with remote!"
                Logger.watch.info("\(errorString)")
            }

            // Setup installation to receive push notifications
            Task {
                await Utility.updateInstallationWithDeviceToken()
            }
        } catch {
            // swiftlint:disable:next line_length
            Logger.login.error("*** Error logging into Parse Server. If you are still having problems check for help here: https://github.com/netreconlab/parse-hipaa#getting-started ***")
            Logger.login.error("Parse error: \(String(describing: error.localizedDescription))")
        }
    }
}
