//
//  LoginViewModel.swift
//  OCKSample
//
//  Created by Corey Baker on 11/24/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import ParseSwift
import CareKit
import CareKitStore
import os.log

@MainActor
class LoginViewModel: ObservableObject {

    private(set) var isLoggedIn = false // Publishes a notification to subscribers whenever this value changes
    private(set) var loginError: ParseError? = nil // Publishes a notification to subscribers whenever this value changes
    private var profileModel: ProfileViewModel?
    
    //MARK: User intentional behavier
    
    /**
     Signs up the user *asynchronously*.

     This will also enforce that the username isn't already taken.

     - parameter username: The username the user is signing in with.
     - parameter password: The password the user is signing in with.
    */
    func signup(username: String, password: String, firstName: String, lastName: String) async {
        
        Task {
            do {
                let user = try await User.signup(username: username, password: password)
                self.profileModel = ProfileViewModel()
                _ = try await self.profileModel?.savePatientAfterSignUp(firstName, last: lastName)
                Logger.login.info("Parse signup successful: \(user)")
                self.isLoggedIn = true
            } catch {
                guard let parseError = error as? ParseError else {
                    return
                }
                switch parseError.code {
                case .usernameTaken:
                    self.loginError = parseError

                default:
                    Logger.login.error("*** Error Signing up as user for Parse Server. Are you running parse-hipaa and is the initialization complete? Check http://localhost:1337 in your browser. If you are still having problems check for help here: https://github.com/netreconlab/parse-postgres#getting-started ***")
                    self.loginError = parseError
                }
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
            let user = try await User.login(username: username, password: password)
            Logger.login.info("Parse login successful: \(user, privacy: .private)")
            self.profileModel = ProfileViewModel()

            do {
                _ = try await self.profileModel?.setupRemoteAfterLoginButtonTapped()
                self.isLoggedIn = true // Notify the SwiftUI view that the user is correctly logged in and to transition screens
                do {
                    // Setup installation to receive push notifications
                    _ = try await Installation.current?.save()
                    Logger.login.info("Parse Installation saved, can now receive push notificaitons.")
                } catch {
                    Logger.login.error("Error saving Parse Installation saved: \(error.localizedDescription)")
                }
            } catch {
                Logger.login.error("Error saving the patient after signup: \(error.localizedDescription, privacy: .public)")
            }
        } catch {
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
            let user = try await User.anonymous.login()
            Logger.login.info("Parse login successful: \(user)")
            self.profileModel = ProfileViewModel()
            _ = try await self.profileModel?.savePatientAfterSignUp("Anonymous", last: "Login")
            self.isLoggedIn = true // Notify the SwiftUI view that the user is correctly logged in and to transition screens

            // Setup installation to receive push notifications
            _ = try await Installation.current?.save()
            Logger.login.info("Parse Installation saved, can now receive push notificaitons.")
        } catch {
            Logger.login.error("*** Error logging into Parse Server. If you are still having problems check for help here: https://github.com/netreconlab/parse-hipaa#getting-started ***")
            Logger.login.error("Parse error: \(String(describing: error))")
            guard let parseError = error as? ParseError else {
                return
            }
            self.loginError = parseError
        }
    }
}

