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
    @Published var isLoggedOut = true

    init() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(userLoggedIn(_:)),
                                               name: Notification.Name(rawValue: Constants.userLoggedIn),
                                               object: nil)
        Task {
            await self.checkStatus()
        }
    }

    @objc private func userLoggedIn(_ notification: Notification) {
        DispatchQueue.main.async {
            self.isLoggedOut = false
        }
    }

    class func setDefaultACL() throws {
        var defaultACL = ParseACL()
        defaultACL.publicRead = false
        defaultACL.publicWrite = false
        _ = try ParseACL.setDefaultACL(defaultACL, withAccessForCurrentUser: true)
    }

    @MainActor
    func checkStatus() {
        if User.current != nil && isLoggedOut {
            isLoggedOut = false
        } else if User.current == nil && !isLoggedOut {
            isLoggedOut = true
        }
    }

    @MainActor
    class func loginFromiPhoneMessage(_ message: [String: Any]) async {
        guard let sessionToken = message[Constants.parseUserSessionTokenKey] as? String else {
            Logger.login.error("Error: data missing in iPhone message")
            return
        }

        do {
            let user = try await User().become(sessionToken: sessionToken)
            Logger.login.info("Parse login successful \(user, privacy: .private)")
            let uuidString = try Utility.getRemoteClockUUID().uuidString
            do {
                try LoginViewModel.setDefaultACL()
            } catch {
                Logger.login.error("Could not set defaultACL: \(error.localizedDescription)")
            }
            guard let watchDelegate = AppDelegateKey.defaultValue else {
                Logger.login.error("ApplicationDelegate should not be nil")
                return
            }
            watchDelegate.setupRemotes(uuid: uuidString)
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
