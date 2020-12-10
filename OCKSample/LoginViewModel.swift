//
//  LoginViewModel.swift
//  OCKSample
//
//  Created by Corey Baker on 11/24/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import Foundation
import ParseSwift
import CareKit
import CareKitStore

class LoginViewModel: ObservableObject {

    private(set) var isLoggedIn = false {
        willSet {
            objectWillChange.send() //Publishes a notification to subscribers whenever this value changes
        }
    }
    private(set) var loginError: ParseError? = nil {
        willSet {
            objectWillChange.send() //Publishes a notification to subscribers whenever this value changes
        }
    }
    private var profileModel: ProfileViewModel?
    
    //MARK: User intentional behavier
    
    /**
     Signs up the user *asynchronously*.

     This will also enforce that the username isn't already taken.

     - parameter username: The username the user is signing in with.
     - parameter password: The password the user is signing in with.
    */
    func signup(username: String, password: String, firstName: String, lastName: String) {
        
        User.signup(username: username, password: password) { result in
            switch result {
            
            case .success(let user):
                print("Parse signup successful: \(user)")
                
                self.profileModel = ProfileViewModel()
                self.profileModel?.savePatientAfterSignUp(firstName, last: lastName) { result in
                    switch result {
                    
                    case .success(_):
                        self.isLoggedIn = true //Notify the SwiftUI view that the user is correctly logged in and to transition screens
                        
                        //Setup installation to receive push notifications
                        Installation.current?.save { result in
                            switch result {
                            
                            case .success(_):
                                print("Parse Installation saved, can now receive push notificaitons.")
                            case .failure(let error):
                                print("Error saving Parse Installation saved: \(error.localizedDescription)")
                            }
                        }
                    case .failure(let error):
                        print("Error saving the patient after signup: \(error)")
                    }
                }

            case .failure(let error):
                
                switch error.code {
                case .usernameTaken: //Account already exists for this username.
                    self.loginError = error //Notify the SwiftUI view that there's an error

                default:
                    //There was a different issue that we don't know how to handle
                    print("*** Error Signing up as user for Parse Server. Are you running parse-hipaa and is the initialization complete? Check http://localhost:1337 in your browser. If you are still having problems check for help here: https://github.com/netreconlab/parse-postgres#getting-started ***")
                    self.loginError = error //Notify the SwiftUI view that there's an error
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
    func login(username: String, password: String) {
        
        User.login(username: username, password: password) { result in

            switch result {
            
            case .success(let user):
                print("Parse login successful: \(user)")
                    
                self.profileModel = ProfileViewModel()
                self.profileModel?.setupRemoteAfterLoginButtonTapped { result in
                    switch result {
                    
                    case .success(_):
                        self.isLoggedIn = true //Notify the SwiftUI view that the user is correctly logged in and to transition screens
                        
                        //Setup installation to receive push notifications
                        Installation.current?.save() { result in
                            switch result {
                            
                            case .success(_):
                                print("Parse Installation saved, can now receive push notificaitons.")
                            case .failure(let error):
                                print("Error saving Parse Installation saved: \(error.localizedDescription)")
                            }
                        }
                    case .failure(let error):
                        print("Error saving the patient after signup: \(error)")
                    }
                }
                
            case .failure(let error):
                print("*** Error logging into Parse Server. If you are still having problems check for help here: https://github.com/netreconlab/parse-hipaa#getting-started ***")
                print("Parse error: \(String(describing: error))")
                
                self.loginError = error //Notify the SwiftUI view that there's an error
            }
        }
    }
}

