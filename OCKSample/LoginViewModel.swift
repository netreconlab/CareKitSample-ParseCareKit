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
    
    //This is another way of making a property read-only for Views to access, but not mess up
    var sychonizationManager: OCKSynchronizedStoreManager {
        parse.appDelegate.synchronizedStoreManager
    }
    
    init() {
        parse = ParseLoginModel()
        isLoggedIn = false
        loginError = nil //Starts off as no error
    }
    
    //MARK: User intentional behavier
    
    func signup(username: String, password: String) {
        parse.signup(username: username, password: password) { result in
            
            switch result {
            
            case .success(_):
                self.isLoggedIn = true
                
            case .failure(let error):
                self.loginError = error
            }
        }
    }
    
    func login(username: String, password: String) {
        //Need to implement, look at login and complete implementation in the model
    }
    
    func logout() throws {
        try parse.logout() //Log out of cloud database
    }
}

