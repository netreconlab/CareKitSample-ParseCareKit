//
//  ParseLoginModel.swift
//  OCKSample
//
//  Created by Corey Baker on 11/24/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import Foundation
import ParseSwift
import UIKit //Note: we are cheating a little here, because the model shouldn't need to import UIKit or SwiftUI, but we don't have time to rework the AppDelegate. The only piece we are using is UIApplication.

struct ParseLoginModel {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate //Importing UIKit gives us access here to get the OCKStore and ParseRemote
    
    /**
     Signs up the user *asynchronously*.

     This will also enforce that the username isn't already taken.

     - warning: Make sure that password and username are set before calling this method.
     - parameter username: The username the user is signing in with.
     - parameter password: The password the user is signing in with.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<User, ParseError>)`.
    */
    func signup(username: String, password: String, completion: @escaping (Result<User,ParseError>) -> Void) {
        User.signup(username: username, password: password) { result in
            switch result {
            
            case .success(let user):
                print("Parse signup successful: \(user)")
                
                //Because of the app delegate access above, we can place the initial data in the database
                self.appDelegate.coreDataStore.populateSampleData()
                self.appDelegate.healthKitStore.populateSampleData()
                self.appDelegate.parse.automaticallySynchronizes = true
                self.appDelegate.firstLogin = true
                
                //Post notification to sync
                NotificationCenter.default.post(.init(name: Notification.Name(rawValue: "requestSync")))
                
                //Finished the async call, return the signed in user
                completion(.success(user))

            case .failure(let parseError):
                switch parseError.code{
                case .usernameTaken: //Account already exists for this username.
                    completion(.failure(parseError))
                default:
                    //There was a different issue that we don't know how to handle
                    print("*** Error Signing up as user for Parse Server. Are you running parse-hipaa and is the initialization complete? Check http://localhost:1337 in your browser. If you are still having problems check for help here: https://github.com/netreconlab/parse-postgres#getting-started ***")
                    completion(.failure(parseError))
                }
            }
        }
    }
    
    /**
     Logs in the user *asynchronously*.

     This will also enforce that the username isn't already taken.

     - warning: Make sure that password and username are set before calling this method.
     - parameter username: The username the user is logging in with.
     - parameter password: The password the user is logging in with.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<User, ParseError>)`.
    */
    func login(username: String, password: String) {
        
        User.login(username: username, password: password) { result in

            switch result {
            
            case .success(let user):
                print("Parse login successful: \(user)")
                
                self.appDelegate.healthKitStore.populateSampleData() //HealthKit data lives in a seperate store and doesn't sync to Cloud
                self.appDelegate.parse.automaticallySynchronizes = true
                self.appDelegate.firstLogin = true
                
                NotificationCenter.default.post(.init(name: Notification.Name(rawValue: "requestSync")))
                    
                //You will need a completion here for the async return
            
            case .failure(let error):
                print("*** Error logging into Parse Server. If you are still having problems check for help here: https://github.com/netreconlab/parse-hipaa#getting-started ***")
                print("Parse error: \(String(describing: error))")
                
                //You will need a completion here for the async return
            }
        }
    }
    
    //You may not have seen "throws" before, but it's simple, this throws an error if one occurs, if not it behaves as normal
    //Normally, you've seen do {} catch{} which catches the error, same concept...
    func logout() throws {
        try User.logout()
        try appDelegate.coreDataStore.delete() //Delete data in local OCKStore database
        appDelegate.setupRemotes() //Create new database
    }
}
