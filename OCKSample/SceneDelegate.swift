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
    let appDelegate = UIApplication.shared.delegate as! AppDelegate

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {

        
        let permissionViewController = UIViewController()
        permissionViewController.view.backgroundColor = .white
        if let windowScene = scene as? UIWindowScene {
            window = UIWindow(windowScene: windowScene)
            window?.rootViewController = permissionViewController
            window?.tintColor = UIColor { $0.userInterfaceStyle == .light ?  #colorLiteral(red: 0, green: 0.2858072221, blue: 0.6897063851, alpha: 1) : #colorLiteral(red: 0.06253327429, green: 0.6597633362, blue: 0.8644603491, alpha: 1) }
            window?.makeKeyAndVisible()

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.appDelegate.healthKitStore.requestHealthKitPermissionsForAllTasksInStore { _ in

                    //When syncing directly with watchOS, we don't care about login and need to setup remotes
                    if !self.appDelegate.syncWithCloud {
                        DispatchQueue.main.async {
                            self.appDelegate.setupRemotes()
                            self.appDelegate.coreDataStore.populateSampleData()
                            self.appDelegate.healthKitStore.populateSampleData()
                            self.goToTabController()
                        }

                    } else {
                        //If the user isn't logged in, log them in
                        if User.current == nil {
                            
                            var newUser = User()
                            newUser.username = "ParseCareKit"
                            newUser.password = "ThisIsAStrongPass1!"
                            
                            newUser.signup { result in
                                switch result {
                                
                                case .success(let user):
                                    print("Parse signup successful \(user)")
                                    //This is in place because Parse-Swift currently has a bug, remove dispatch on bug fix
                                    DispatchQueue.main.async {
                                        self.appDelegate.setupRemotes()
                                        self.appDelegate.coreDataStore.populateSampleData()
                                        self.appDelegate.healthKitStore.populateSampleData()
                                        self.goToTabController()
                                    }
                                    
                                case .failure(let parseError):
                                    switch parseError.code{
                                    case .usernameTaken: //Account already exists for this username.
                                        User.login(username: newUser.username!, password: newUser.password!) { result in

                                            switch result {
                                            
                                            case .success(let user):
                                                print("Parse login successful \(user)")
                                                //This is in place because Parse-Swift currently has a bug, remove dispatch on bug fix
                                                DispatchQueue.main.async {
                                                self.appDelegate.setupRemotes()
                                                self.goToTabController()
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
                            DispatchQueue.main.async {
                                self.appDelegate.setupRemotes()
                                self.appDelegate.coreDataStore.synchronize { error in
                                    print(error?.localizedDescription ?? "Completed sync in DailyPageViewController")
                                }
                                self.goToTabController()
                            }
                        }
                    }
                }
            }
        }
    }
    
    func goToTabController() {
        
        let manager = self.appDelegate.synchronizedStoreManager!
        let care = CareViewController(storeManager: manager)
        care.tabBarItem = UITabBarItem(title: "Patient Care", image: .init(imageLiteralResourceName: "carecard"), selectedImage: .init(imageLiteralResourceName: "carecard-filled"))
        let careViewController = UINavigationController(rootViewController: care)
        
        let contacts = OCKContactsListViewController(storeManager: manager)
        contacts.title = "Contacts"
        contacts.tabBarItem = UITabBarItem(title: "Contacts", image: .init(imageLiteralResourceName: "connect"), selectedImage: .init(imageLiteralResourceName: "connect-filled"))
        let contactViewController = UINavigationController(rootViewController: contacts)
        let tabBarController = UITabBarController()
        tabBarController.viewControllers = [careViewController, contactViewController]
        self.window?.rootViewController = tabBarController
    }
}
