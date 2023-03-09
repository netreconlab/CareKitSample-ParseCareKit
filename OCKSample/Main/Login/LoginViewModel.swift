//
//  LoginViewModel.swift
//  OCKSample
//
//  Created by Corey Baker on 11/24/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import ParseCareKit
import ParseSwift
import CareKit
import CareKitStore
import WatchConnectivity
import os.log

class LoginViewModel: ObservableObject {

    // MARK: Public read, private write properties
    @Published private(set) var isLoggedOut = true {
        willSet {
            /*
             Publishes a notification to subscribers whenever this value changes.
             This is what the @Published property wrapper gives you for free
             everytime you use it to wrap a property.
            */
            objectWillChange.send()
            if newValue {
                self.sendUpdatedUserStatusToWatch()
            }
        }
    }
    @Published private(set) var loginError: ParseError?

    init() {
        Task {
            await checkStatus()
        }
    }

    // MARK: Helpers (private)
    private func checkStatus() async {
        let isLoggedOut = self.isLoggedOut
        do {
            _ = try await User.current()
            if isLoggedOut {
                DispatchQueue.main.async {
                    self.isLoggedOut = false
                }
            }
        } catch {
            if !isLoggedOut {
                DispatchQueue.main.async {
                    self.isLoggedOut = true
                }
            }
        }
    }

    private func sendUpdatedUserStatusToWatch() {
        Task {
            do {
                let message = try await Utility.getUserSessionForWatch()
                DispatchQueue.main.async {
                    WCSession.default.sendMessage(message,
                                                  replyHandler: nil,
                                                  errorHandler: nil)
                }
            } catch {
                Logger.login.info("Could not get session for watch: \(error)")
                return
            }
        }
    }

    @MainActor
    private func finishCompletingSignIn(_ careKitPatient: OCKPatient? = nil) async throws {
        if let careKitUser = careKitPatient {
            var user = try await User.current()
            guard let userType = careKitUser.userType,
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
                Logger.login.info("Could not save updated user: \(error)")
            }
        }

        // Notify the SwiftUI view that the user is correctly logged in and to transition screens
        await checkStatus()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            NotificationCenter.default.post(.init(name: Notification.Name(rawValue: Constants.requestSync)))
            Utility.requestHealthKitPermissions()
        }

        // Setup installation to receive push notifications
        await Utility.updateInstallationWithDeviceToken()
    }

    @MainActor
    private func savePatientAfterSignUp(_ type: UserType,
                                        firstName: String,
                                        lastName: String) async throws -> OCKPatient {
        let remoteUUID = UUID()
        do {
            try await Utility.setDefaultACL()
        } catch {
            Logger.login.error("Could not set defaultACL: \(error)")
        }

        guard let appDelegate = AppDelegateKey.defaultValue else {
            throw AppError.couldntBeUnwrapped
        }
        try await appDelegate.setupRemotes(uuid: remoteUUID)
        let storeManager = appDelegate.storeManager

        var newPatient = OCKPatient(remoteUUID: remoteUUID,
                                    id: remoteUUID.uuidString,
                                    givenName: firstName,
                                    familyName: lastName)
        newPatient.userType = type
        let savedPatient = try await storeManager.store.addAnyPatient(newPatient)
        guard let patient = savedPatient as? OCKPatient else {
            throw AppError.couldntCast
        }

        try await appDelegate.store?.populateSampleData()
        try await appDelegate.healthKitStore.populateSampleData()
        appDelegate.parseRemote.automaticallySynchronizes = true

        // Post notification to sync
        NotificationCenter.default.post(.init(name: Notification.Name(rawValue: Constants.requestSync)))
        Logger.login.info("Successfully added a new Patient")
        return patient
    }

    // MARK: User intentional behavior
    /**
     Signs up the user *asynchronously*.

     This will also enforce that the username is not already taken.
     - parameter username: The username the person signing up.
     - parameter password: The password the person signing up.
     - parameter firstName: The first name of the person signing up.
     - parameter lastName: The last name of the person signing up.
    */
    @MainActor
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
            newUser.username = username.lowercased()
            newUser.password = password
            let user = try await newUser.signup()
            Logger.login.info("Parse signup successful: \(user)")
            let patient = try await savePatientAfterSignUp(type,
                                                           firstName: firstName,
                                                           lastName: lastName)
            try? await finishCompletingSignIn(patient)
        } catch {
            Logger.login.error("Error details: \(error)")
            guard let parseError = error as? ParseError else {
                return
            }
            switch parseError.code {
            case .usernameTaken:
                self.loginError = parseError

            default:
                // swiftlint:disable:next line_length
                Logger.login.error("*** Error Signing up as user for Parse Server. Are you running parse-hipaa and is the initialization complete? Check http://localhost:1337 in your browser. If you are still having problems check for help here: https://github.com/netreconlab/parse-postgres#getting-started ***.")
                self.loginError = parseError
            }
        }
    }

    /**
     Logs in the user *asynchronously*.

     The user must have already signed up.
     - parameter username: The username the person logging in.
     - parameter password: The password the person logging in.
    */
    @MainActor
    func login(username: String,
               password: String) async {
        do {
            guard try await PCKUtility.isServerAvailable() else {
                Logger.login.error("Server health is not \"ok\"")
                return
            }
            let user = try await User.login(username: username.lowercased(), password: password)
            Logger.login.info("Parse login successful: \(user, privacy: .private)")
            AppDelegateKey.defaultValue?.isFirstTimeLogin = true
            do {
                try await Utility.setupRemoteAfterLogin()
                try await finishCompletingSignIn()
            } catch {
                Logger.login.error("Error saving the patient after signup: \(error, privacy: .public)")
            }
        } catch {
            // swiftlint:disable:next line_length
            Logger.login.error("*** Error logging into Parse Server. If you are still having problems check for help here: https://github.com/netreconlab/parse-hipaa#getting-started ***")
            Logger.login.error("Error details: \(error)")
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
    @MainActor
    func loginAnonymously() async {
        do {
            guard try await PCKUtility.isServerAvailable() else {
                Logger.login.error("Server health is not \"ok\"")
                return
            }
            let user = try await User.anonymous.login()
            Logger.login.info("Parse login anonymous successful: \(user)")
            // Only allow annonymous users to be patients.
            let patient = try await savePatientAfterSignUp(.patient,
                                                           firstName: "Anonymous",
                                                           lastName: "Login")
            try? await finishCompletingSignIn(patient)
        } catch {
            // swiftlint:disable:next line_length
            Logger.login.error("*** Error logging into Parse Server. If you are still having problems check for help here: https://github.com/netreconlab/parse-hipaa#getting-started ***")
            Logger.login.error("Error details: \(String(describing: error))")
            guard let parseError = error as? ParseError else {
                return
            }
            self.loginError = parseError
        }
    }

    /**
     Logs out the currently logged in person *asynchronously*.
    */
    @MainActor
    func logout() async {
        // You may not have seen "throws" before, but it's simple,
        // this throws an error if one occurs, if not it behaves as normal
        // Normally, you've seen do {} catch {} which catches the error, same concept...
        do {
            try await User.logout()
        } catch {
            Logger.login.error("Error logging out: \(error)")
        }
        AppDelegateKey.defaultValue?.resetAppToInitialState()
        await self.checkStatus()
    }
}
