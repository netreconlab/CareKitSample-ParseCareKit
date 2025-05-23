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
	@Published private(set) var isLoggedIn: Bool?

    // MARK: Helpers (private)

    @MainActor
    func checkStatus() async {
        do {
            _ = try await User.current()
			self.isLoggedIn = true
        } catch {
			self.isLoggedIn = false
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
            let user = try await User.become(sessionToken: sessionToken)
            Logger.login.info("Parse login successful \(user, privacy: .private)")
            try await Utility.setupRemoteAfterLogin()

            // Setup installation to receive push notifications
            Task {
                await Utility.updateInstallationWithDeviceToken()
            }
        } catch {
            // swiftlint:disable:next line_length
            Logger.login.error("*** Error logging into Parse Server. If you are still having problems check for help here: https://github.com/netreconlab/parse-hipaa#getting-started ***")
            Logger.login.error("Parse error: \(String(describing: error))")
        }
    }
}
