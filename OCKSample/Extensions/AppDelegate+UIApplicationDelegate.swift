//
//  AppDelegate+UIApplicationDelegate.swift
//  OCKSample
//
//  Created by Corey Baker on 9/19/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import UIKit
import ParseCareKit
import os.log

extension AppDelegate: UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Parse-Server setup
        PCKUtility.setupServer(fileName: Constants.parseConfigFileName) { _, completionHandler in
            completionHandler(.performDefaultHandling, nil)
        }
        return true
    }

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        if isSyncingWithCloud {
            if User.current != nil {
                Logger.appDelegate.info("User is already signed in...")
                guard let uuid = ProfileViewModel.getRemoteClockUUIDAfterLoginFromLocalStorage() else {
                    Logger.appDelegate.info("Error in SceneDelage, no uuid saved.")
                    return UISceneConfiguration(name: "Default Configuration",
                                                sessionRole: connectingSceneSession.role)
                }
                setupRemotes(uuid: uuid)
                parseRemote.automaticallySynchronizes = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    NotificationCenter.default.post(.init(name: Notification.Name(rawValue: Constants.requestSync)))
                }
            }
        } else {
            // When syncing directly with watchOS, we do not care about login and need to setup remotes
            setupRemotes()
            Task {
                do {
                    try await store?.populateSampleData()
                    try await healthKitStore.populateSampleData()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.healthKitStore.requestHealthKitPermissionsForAllTasksInStore { error in

                            if error != nil {
                                Logger.appDelegate.error("\(error!.localizedDescription)")
                            }
                        }
                    }
                } catch {
                    Logger.appDelegate.error("""
                        Error in SceneDelage, could not populate
                        data stores: \(error.localizedDescription)
                    """)
                }
            }
        }
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {}

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Task {
            await Utility.updateInstallationWithDeviceToken(deviceToken)
        }
    }
}
