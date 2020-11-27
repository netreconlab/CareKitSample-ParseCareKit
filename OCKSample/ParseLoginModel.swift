//
//  ParseLoginModel.swift
//  OCKSample
//
//  Created by Corey Baker on 11/24/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import Foundation
import ParseSwift

struct ParseLoginModel {
    
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
    func login(username: String, password: String, completion: @escaping (Result<User,ParseError>)-> Void) {
        
        User.login(username: username, password: password) { result in

            switch result {
            
            case .success(let user):
                print("Parse login successful: \(user)")
                    
                completion(.success(user))
                
            case .failure(let error):
                print("*** Error logging into Parse Server. If you are still having problems check for help here: https://github.com/netreconlab/parse-hipaa#getting-started ***")
                print("Parse error: \(String(describing: error))")
                
                completion(.failure(error))
            }
        }
    }
}
