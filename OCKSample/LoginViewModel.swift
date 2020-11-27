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
    
    private(set) var parse: ParseLoginModel
    private(set) var isLoggedIn: Bool {
        willSet {
            objectWillChange.send() //Publishes a notification to subscribers whenever this value changes
        }
    }
    private(set) var loginError: ParseError? {
        willSet {
            objectWillChange.send() //Publishes a notification to subscribers whenever this value changes
        }
    }
    
    private var profileModel: ProfileViewModel?
    
    init() {
        parse = ParseLoginModel()
        isLoggedIn = false
        loginError = nil //Starts off as no error
    }
    
    //MARK: User intentional behavier
    
    func signup(username: String, password: String, firstName: String, lastName: String) {
        parse.signup(username: username, password: password) { result in
            
            switch result {
            
            case .success(_):
                self.profileModel = ProfileViewModel()
                self.profileModel?.savePatientAfterSignUp(firstName, last: lastName) { result in
                    switch result {
                    
                    case .success(_):
                        self.isLoggedIn = true //Notify the SwiftUI view that the user is correctly logged in and to transition screens
                        
                    case .failure(let error):
                        print("Error saving the patient after signup: \(error)")
                    }
                }
                
            case .failure(let error):
                self.loginError = error //Notify the SwiftUI view that there's an error
            }
        }
    }
    
    func login(username: String, password: String) {
        parse.login(username: username, password: password) { result in
            
            switch result {
            
            case .success(_):
                self.profileModel = ProfileViewModel()
                self.profileModel?.setupRemoteAfterLoginButtonTapped { result in
                    switch result {
                    
                    case .success(_):
                        self.isLoggedIn = true //Notify the SwiftUI view that the user is correctly logged in and to transition screens
                        
                    case .failure(let error):
                        print("Error saving the patient after signup: \(error)")
                    }
                }
                
            case .failure(let error):
                self.loginError = error //Notify the SwiftUI view that there's an error
            }
        }
    }
}

