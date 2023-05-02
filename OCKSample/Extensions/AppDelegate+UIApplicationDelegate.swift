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
        Task {
            if isSyncingWithRemote {
                do {
                    // Parse-Server setup
                    // swiftlint:disable:next line_length
                    try await PCKUtility.configureParse(fileName: Constants.parseConfigFileName) { _, completionHandler in
                        completionHandler(.performDefaultHandling, nil)
                    }
                } catch {
                    Logger.appDelegate.info("Could not configure Parse Swift: \(error)")
                    return
                }
                await Utility.clearDeviceOnFirstRun()
                do {
                    _ = try await User.current()
                    Logger.appDelegate.info("User is already signed in...")
                    do {
                        let uuid = try await Utility.getRemoteClockUUID()
                        try? await setupRemotes(uuid: uuid)
                        parseRemote.automaticallySynchronizes = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            // swiftlint:disable:next line_length
                            NotificationCenter.default.post(.init(name: Notification.Name(rawValue: Constants.requestSync)))
                        }
                    } catch {
                        Logger.appDelegate.error("User is logged in, but missing remoteId: \(error)")
                        try await setupRemotes()
                    }
                } catch {
                    Logger.appDelegate.error("User is not loggied in: \(error)")
                }
            } else {
                await Utility.clearDeviceOnFirstRun()
                // When syncing directly with watchOS, we do not care about login and need to setup remotes
                do {
                    try await setupRemotes()
                    try await store.populateSampleData()
                    try await healthKitStore.populateSampleData()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        NotificationCenter.default.post(.init(name: Notification.Name(rawValue: Constants.requestSync)))
                        Utility.requestHealthKitPermissions()
                    }
                } catch {
                    Logger.appDelegate.error("""
                        Could not populate
                        data stores: \(error)
                    """)
                }
            }
        }
        return true
    }

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
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
