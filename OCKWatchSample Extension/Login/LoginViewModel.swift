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

@MainActor
class LoginViewModel: ObservableObject {
    // swiftlint:disable:next force_cast
    private let watchDelegate = WKExtension.shared().delegate as! ExtensionDelegate

    var syncWithCloud: Bool {
        return watchDelegate.syncWithCloud
    }

    @Published var isLoggedOut = true

    init() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(userLoggedIn(_:)),
                                               name: Notification.Name(rawValue: Constants.userLoggedIn),
                                               object: nil)
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

    class func loginFromiPhoneMessage(_ message: [String: Any]) async {
        guard let sessionToken = message[Constants.parseUserSessionTokenKey] as? String,
              let uuidString = message[Constants.parseRemoteClockIDKey] as? String else {
                  Logger.feed.error("Error: data missing in iPhone message")
                  return
        }

        // Save remoteUUID for later
        UserDefaults.standard.setValue(uuidString, forKey: Constants.parseRemoteClockIDKey)
        UserDefaults.standard.synchronize()

        do {
            let user = try await User().become(sessionToken: sessionToken)
            Logger.feed.info("Parse login successful \(user, privacy: .private)")

            do {
                try LoginViewModel.setDefaultACL()
            } catch {
                Logger.profile.error("Couldn't set defaultACL: \(error.localizedDescription)")
            }

            // swiftlint:disable:next force_cast
            let watchDelegate = WKExtension.shared().delegate as! ExtensionDelegate
            watchDelegate.setupRemotes(uuid: uuidString)
            watchDelegate.store.synchronize { error in
                let errorString = error?.localizedDescription ?? "Successful sync with remote!"
                Logger.watch.info("\(errorString)")
            }
            NotificationCenter.default.post(.init(name: Notification.Name(rawValue: Constants.userLoggedIn)))
            // Setup installation to receive push notifications
            Task {
                await Utility.updateInstallationWithDeviceToken()
            }
        } catch {
            // swiftlint:disable:next line_length
            Logger.feed.error("*** Error logging into Parse Server. If you are still having problems check for help here: https://github.com/netreconlab/parse-hipaa#getting-started ***")
            Logger.feed.error("Parse error: \(String(describing: error.localizedDescription))")
        }
    }
}
