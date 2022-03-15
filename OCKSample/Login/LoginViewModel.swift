//
//  LoginViewModel.swift
//  OCKSample
//
//  Created by Corey Baker on 11/24/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import UIKit
import ParseCareKit
import ParseSwift
import CareKit
import CareKitStore
import WatchConnectivity
import os.log

class LoginViewModel: ObservableObject {

    @Published private(set) var isLoggedOut = true {
        willSet {
            // Publishes a notification to subscribers whenever this value changes
            objectWillChange.send()
            let message = Utility.getUserSessionForWatch()
            WCSession.default.sendMessage(message,
                                          replyHandler: nil,
                                          errorHandler: nil)
        }
    }

    @Published private(set) var loginError: ParseError?
    private let profileViewModel: ProfileViewModel = ProfileViewModelKey.defaultValue

    // MARK: Helpers
    @MainActor
    private func finishCompletingSignIn(_ careKitPatient: OCKPatient? = nil) async throws {

        if let careKitUser = careKitPatient {
            guard var user = User.current,
                let userType = careKitUser.userType,
                let remoteUUID = careKitUser.remoteClockUUID else {
                return
            }
            user.lastTypeSelected = userType.rawValue
            if user.userTypeUUIDs != nil {
                user.userTypeUUIDs?[userType.rawValue] = remoteUUID
            } else {
                user.userTypeUUIDs = [userType.rawValue: remoteUUID]
            }
            do {
                _ = try await user.save()
            } catch {
                Logger.login.info("Couldn't save updated user: \(error.localizedDescription)")
            }
        }

        // swiftlint:disable:next force_cast
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.isFirstLogin = true

        if StoreManagerKey.defaultValue != nil {
            profileViewModel.refreshViewIfNeeded()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                NotificationCenter.default.post(.init(name: Notification.Name(rawValue: Constants.requestSync)))
                appDelegate.healthKitStore.requestHealthKitPermissionsForAllTasksInStore { error in

                    if error != nil {
                        Logger.login.error("Error requesting HealthKit permissions: \(error!.localizedDescription)")
                    }
                }
            }
        } else {
            Logger.login.info("StoreManager should not be nil")
        }

        // Notify the SwiftUI view that the user is correctly logged in and to transition screens
        self.isLoggedOut = false

        // Setup installation to receive push notifications
        Task {
            await Utility.updateInstallationWithDeviceToken()
        }
    }

    class func setDefaultACL() throws {
        var defaultACL = ParseACL()
        defaultACL.publicRead = false
        defaultACL.publicWrite = false
        _ = try ParseACL.setDefaultACL(defaultACL, withAccessForCurrentUser: true)
    }

    // MARK: User intentional behavier

    /**
     Signs up the user *asynchronously*.

     This will also enforce that the username isn't already taken.

     - parameter username: The username the user is signing in with.
     - parameter password: The password the user is signing in with.
    */
    func signup(_ type: UserType,
                username: String,
                password: String,
                firstName: String,
                lastName: String) async {

        do {
            guard try await PCKUtility.isServerAvailable() else {
                Logger.login.error("Server health is not \"ok\"")
                return
            }
            var newUser = User()
            // Set any properties you want saved on the user befor logging in.
            newUser.username = username
            newUser.password = password
            let user = try await newUser.signup()
            Logger.login.info("Parse signup successful: \(user)")
            let patient = try await ProfileViewModel.savePatientAfterSignUp(type,
                                                                            first: firstName,
                                                                            last: lastName)
            try? await finishCompletingSignIn(patient)

        } catch {
            guard let parseError = error as? ParseError else {
                return
            }
            switch parseError.code {
            case .usernameTaken:
                self.loginError = parseError

            default:
                // swiftlint:disable:next line_length
                Logger.login.error("*** Error Signing up as user for Parse Server. Are you running parse-hipaa and is the initialization complete? Check http://localhost:1337 in your browser. If you are still having problems check for help here: https://github.com/netreconlab/parse-postgres#getting-started ***")
                self.loginError = parseError
            }
        }
    }

    /**
     Logs in the user *asynchronously*.

     This will also enforce that the username isn't already taken.

     - parameter username: The username the user is logging in with.
     - parameter password: The password the user is logging in with.
    */
    func login(username: String, password: String) async {

        do {
            guard try await PCKUtility.isServerAvailable() else {
                Logger.login.error("Server health is not \"ok\"")
                return
            }
            let user = try await User.login(username: username, password: password)
            Logger.login.info("Parse login successful: \(user, privacy: .private)")

            do {
                try await ProfileViewModel.setupRemoteAfterLoginButtonTapped()
                try? await finishCompletingSignIn()
            } catch {
                // swiftlint:disable:next line_length
                Logger.login.error("Error saving the patient after signup: \(error.localizedDescription, privacy: .public)")
            }
        } catch {
            // swiftlint:disable:next line_length
            Logger.login.error("*** Error logging into Parse Server. If you are still having problems check for help here: https://github.com/netreconlab/parse-hipaa#getting-started ***")
            Logger.login.error("Parse error: \(String(describing: error))")
            guard let parseError = error as? ParseError else {
                // Handle unknow error, right now it's silent
                return
            }
            self.loginError = parseError // Notify the SwiftUI view that there's an error
        }
    }

    /**
     Logs in the user anonymously *asynchronously*.
    */
    func loginAnonymously() async {

        do {
            guard try await PCKUtility.isServerAvailable() else {
                Logger.login.error("Server health is not \"ok\"")
                return
            }
            let user = try await User.anonymous.login()
            Logger.login.info("Parse login anonymous successful: \(user)")
            // Only allow annonymous users to be patients.
            let patient = try await ProfileViewModel.savePatientAfterSignUp(.patient,
                                                                            first: "Anonymous",
                                                                            last: "Login")
            try? await finishCompletingSignIn(patient)

        } catch {
            // swiftlint:disable:next line_length
            Logger.login.error("*** Error logging into Parse Server. If you are still having problems check for help here: https://github.com/netreconlab/parse-hipaa#getting-started ***")
            Logger.login.error("Parse error: \(String(describing: error))")
            guard let parseError = error as? ParseError else {
                return
            }
            self.loginError = parseError
        }
    }
}
