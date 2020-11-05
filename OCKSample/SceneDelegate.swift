/*
 Copyright (c) 2019, Apple Inc. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 3. Neither the name of the copyright holder(s) nor the names of any contributors
 may be used to endorse or promote products derived from this software without
 specific prior written permission. No license is granted to the trademarks of
 the copyright holders even if such marks are included in this software.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import CareKit
import UIKit
import CareKitStore

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {

        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let permissionViewController = UIViewController()
        permissionViewController.view.backgroundColor = .white
        if let windowScene = scene as? UIWindowScene {
            window = UIWindow(windowScene: windowScene)
            window?.rootViewController = permissionViewController
            window?.tintColor = UIColor { $0.userInterfaceStyle == .light ?  #colorLiteral(red: 0, green: 0.2858072221, blue: 0.6897063851, alpha: 1) : #colorLiteral(red: 0.06253327429, green: 0.6597633362, blue: 0.8644603491, alpha: 1) }
            window?.makeKeyAndVisible()

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                appDelegate.healthKitStore.requestHealthKitPermissionsForAllTasksInStore { _ in

                    //If the user isn't logged in, log them in
                    if User.current == nil {
                        
                        var newUser = User()
                        newUser.username = "ParseCareKit"
                        newUser.password = "ThisIsAStrongPass1!"
                        
                        newUser.signup(callbackQueue: .main) { result in
                            switch result {
                            
                            case .success(let user):
                                print("Parse signup successful \(user)")
                                appDelegate.setupRemotes()
                                appDelegate.coreDataStore.populateSampleData()
                                appDelegate.healthKitStore.populateSampleData()

                                DispatchQueue.main.async {
                                    let manager = appDelegate.synchronizedStoreManager!
                                    let careViewController: UINavigationController = UINavigationController(rootViewController: CareViewController(storeManager: manager))
                                    self.window?.rootViewController = careViewController
                                }
                                                                    
                            case .failure(let parseError):
                                switch parseError.code{
                                case .usernameTaken: //Account already exists for this username.
                                    User.login(username: newUser.username!, password: newUser.password!, callbackQueue: .main) { result in
                                            
                                        switch result {
                                        
                                        case .success(let user):
                                            print("Parse login successful \(user)")
                                            appDelegate.setupRemotes()
                                            
                                            DispatchQueue.main.async {
                                                let manager = appDelegate.synchronizedStoreManager!
                                                let careViewController: UINavigationController = UINavigationController(rootViewController: CareViewController(storeManager: manager))
                                                self.window?.rootViewController = careViewController
                                            }
                                                
                                        case .failure(let error):
                                            print("*** Error logging into Parse Server. If you are still having problems check for help here: https://github.com/netreconlab/parse-hipaa#getting-started ***")
                                            print("Parse error: \(String(describing: error))")
                                        }
                                    }
                                default:
                                    //There was a different issue that we don't know how to handle
                                    print("*** Error Signing up as user for Parse Server. Are you running parse-hipaa and is the initialization complete? Check http://localhost:1337 in your browser. If you are still having problems check for help here: https://github.com/netreconlab/parse-postgres#getting-started ***")
                                    print(parseError)
                                }
                            }
                        }
                    } else {
                        print("User is already signed in...")
                        appDelegate.setupRemotes()
                        appDelegate.coreDataStore.synchronize { error in
                            print(error?.localizedDescription ?? "Completed sync in DailyPageViewController")
                        }
                        DispatchQueue.main.async {
                            let manager = appDelegate.synchronizedStoreManager!
                            let careViewController: UINavigationController = UINavigationController(rootViewController: CareViewController(storeManager: manager))
                            self.window?.rootViewController = careViewController
                        }
                    }
                }
            }
        }
    }
}
