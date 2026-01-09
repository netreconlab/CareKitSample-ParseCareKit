//
//  LoginViewModel.swift
//  OCKSample
//
//  Created by Corey Baker on 11/24/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
//

import CareKit
import CareKitStore
import ParseCareKit
import ParseSwift
import os.log
import WatchConnectivity

@MainActor
class LoginViewModel: ObservableObject, @unchecked Sendable {

    // MARK: Public read, private write properties
	@Published private(set) var isLoggedIn: Bool? {
        willSet {
            /*
             Publishes a notification to subscribers whenever this value changes.
             This is what the @Published property wrapper gives you for free
             everytime you use it to wrap a property.
            */
            objectWillChange.send()
            if newValue != nil {
                self.sendUpdatedUserSessionTokenToWatch()
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
    func checkStatus() async {
        do {
            _ = try await User.current()
			self.isLoggedIn = true
        } catch {
			self.isLoggedIn = false
        }
    }

    private func sendUpdatedUserSessionTokenToWatch() {
        Task {
            do {
                let message = try await Utility.getUserSessionForWatch()
				DispatchQueue.global(qos: .default).async {
					// WCSession.default.sendMessage crashes when sending on MainActor
					// so we call on a less important queue.
					WCSession.default.sendMessage(
						message,
						replyHandler: nil,
						errorHandler: { error in
							Logger.remoteSessionDelegate.info("Could not send updated session token to watch: \(error)")
						}
					)
				}
            } catch {
                Logger.login.info("Could not get session token for watch: \(error)")
                return
            }
        }
    }

    private func finishCompletingSignIn(
		_ careKitPatient: OCKPatient? = nil
	) async throws {
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

    private func savePatientAfterSignUp(
		_ type: UserType,
		firstName: String,
		lastName: String
	) async throws -> OCKPatient {

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

        var newPatient = OCKPatient(
			remoteUUID: remoteUUID,
			id: remoteUUID.uuidString,
			givenName: firstName,
			familyName: lastName
		)
        newPatient.userType = type
        let savedPatient = try await appDelegate.store.addPatient(newPatient)

		let currentDate = Date()
		let startDate = daysInThePastToGenerateSampleData < 0 ? Calendar.current.date(
			byAdding: .day,
			value: daysInThePastToGenerateSampleData,
			to: currentDate
		)! : currentDate
        try await appDelegate.store.populateDefaultCarePlansTasksContacts(
			startDate: startDate
		)
        try await appDelegate.healthKitStore.populateDefaultHealthKitTasks(
			startDate: startDate
		)
		if startDate < currentDate {
			try await appDelegate.store.populateSampleOutcomes(
				startDate: startDate
			)
		}
        appDelegate.parseRemote.automaticallySynchronizes = true

        // Post notification to sync
        NotificationCenter.default.post(.init(name: Notification.Name(rawValue: Constants.requestSync)))
        Logger.login.info("Successfully added a new Patient")
        return savedPatient
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
    func signup(
		_ type: UserType,
		username: String,
		password: String,
		firstName: String,
		lastName: String
	) async {
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
                Logger.login.error("*** Error Signing up as user for Parse Server. Are you running parse-hipaa and is the initialization complete? Check http://localhost:1337 in your browser. If you are still having problems check for help here: https://github.com/netreconlab/parse-postgres#getting-started ***")
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
    func login(
		username: String,
		password: String
	) async {
        do {
            guard try await PCKUtility.isServerAvailable() else {
                Logger.login.error("Server health is not \"ok\"")
                return
            }
            let user = try await User.login(username: username.lowercased(), password: password)
            Logger.login.info("Parse login successful: \(user, privacy: .private)")
            AppDelegateKey.defaultValue?.setFirstTimeLogin(true)
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
    func logout() async {
		await Utility.logoutAndResetAppState()
        await self.checkStatus()
    }
}
