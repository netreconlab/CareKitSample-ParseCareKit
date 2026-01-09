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
    // MARK: Public read, private write properties
	@Published private(set) var isLoggedIn: Bool?

    // MARK: Helpers (private)

    func checkStatus() async {
        do {
            _ = try await User.current()
			self.isLoggedIn = true
        } catch {
			self.isLoggedIn = false
        }
    }

    // MARK: Helpers (public)
    static func loginFromiPhoneMessage(_ message: [String: String]) async {
        guard let sessionToken = message[Constants.parseUserSessionTokenKey] else {
            Logger.login.error("Error: data missing in iPhone message")
            return
        }

		do {
			let currentSessionToken = try await User.sessionToken()
			guard currentSessionToken != sessionToken else {
				Logger.login.info("Already logged in with same token as iPhone")
				return
			}
			await Utility.logoutAndResetAppState()
			await loginWithSessionToken(sessionToken)
		} catch {
			await loginWithSessionToken(sessionToken)
		}
    }

	static func loginWithSessionToken(_ sessionToken: String) async {
		do {
			let user = try await User.become(sessionToken: sessionToken)
			Logger.login.info("Parse login successful \(user, privacy: .private)")
			try await Utility.setupRemoteAfterLogin()

			// Setup installation to receive push notifications
			await Utility.updateInstallationWithDeviceToken()
		} catch {
			// swiftlint:disable:next line_length
			Logger.login.error("*** Error logging into Parse Server. If you are still having problems check for help here: https://github.com/netreconlab/parse-hipaa#getting-started ***")
			Logger.login.error("Parse error: \(String(describing: error))")
		}
	}
}
