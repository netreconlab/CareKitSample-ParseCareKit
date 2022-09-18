//
//  AppDelegate.swift
//  OCKWatchSample Extension
//
//  Created by Corey Baker on 6/25/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
//

import CareKit
import CareKitStore
import ParseCareKit
import ParseSwift
import WatchKit
import WatchConnectivity
import os.log

class AppDelegate: NSObject, WKApplicationDelegate, ObservableObject {

    let isSyncingWithCloud = true // True to sync with ParseServer, False to Sync with iOS Phone
    private var parseRemote: ParseRemote!
    private var sessionDelegate: SessionDelegate!
    private lazy var phone = OCKWatchConnectivityPeer()
    private(set) var store: OCKStore!
    @Published private(set) var storeManager: OCKSynchronizedStoreManager! {
        willSet {
            StoreManagerKey.defaultValue = newValue
            DispatchQueue.main.async {
                NotificationCenter.default.post(.init(name: Notification.Name(rawValue: Constants.storeInitialized)))
            }
        }
    }

    func applicationDidFinishLaunching() {
        // Parse-server setup
        PCKUtility.setupServer(fileName: Constants.parseConfigFileName) { _, completionHandler in
            completionHandler(.performDefaultHandling, nil)
        }

        // If the user is not logged in, log them in
        if User.current != nil {
            // swiftlint:disable:next line_length
            self.setupRemotes(uuid: UserDefaults.standard.object(forKey: Constants.parseRemoteClockIDKey) as? String) // Setup for getting info
            NotificationCenter.default.post(.init(name: Notification.Name(rawValue: Constants.userLoggedIn)))
            Logger.appDelegate.info("User is already signed in...")
            store.synchronize { error in
                let errorString = error?.localizedDescription ?? "Successful sync with remote!"
                Logger.appDelegate.info("\(errorString)")
            }
        } else {
            setupRemotes(uuid: nil) // Setup for getting info
        }
    }

    func didRegisterForRemoteNotifications(withDeviceToken deviceToken: Data) {
        Task {
            await Utility.updateInstallationWithDeviceToken(deviceToken)
        }
    }

    func setupRemotes(uuid: String? = nil) {
        do {
            if isSyncingWithCloud {
                if sessionDelegate == nil {
                    sessionDelegate = RemoteSessionDelegate(store: nil)
                    WCSession.default.delegate = sessionDelegate
                }
                guard let uuid = uuid,
                      let remoteUUID = UUID(uuidString: uuid) else {
                          Logger.appDelegate.error("Could not get remote clock UUID from User defaults")
                          WCSession.default.activate()
                          return
                }
                parseRemote = try ParseRemote(uuid: remoteUUID, auto: true, subscribeToServerUpdates: true)
                store = OCKStore(name: Constants.watchOSParseCareStoreName,
                                 remote: parseRemote)
                parseRemote?.parseRemoteDelegate = self
                sessionDelegate.store = store
                storeManager = OCKSynchronizedStoreManager(wrapping: store)

            } else {
                store = OCKStore(name: Constants.watchOSLocalCareStoreName,
                                 remote: phone)
                phone.delegate = self
                sessionDelegate = LocalSessionDelegate(remote: phone, store: store)
                storeManager = OCKSynchronizedStoreManager(wrapping: store)
            }
            WCSession.default.activate()

        } catch {
            Logger.appDelegate.error("Error setting up remote: \(error.localizedDescription)")
        }

    }

    func applicationDidBecomeActive() {
        // swiftlint:disable:next line_length
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillResignActive() {
        // swiftlint:disable:next line_length
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        // swiftlint:disable:next line_length
        // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
        for task in backgroundTasks {
            // Use a switch statement to check the task type
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                // Be sure to complete the background task once you’re done.
                backgroundTask.setTaskCompletedWithSnapshot(false)
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                // Snapshot tasks have a unique completion call, make sure to set your expiration date
                snapshotTask.setTaskCompleted(restoredDefaultState: true,
                                              estimatedSnapshotExpiration: Date.distantFuture,
                                              userInfo: nil)
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                // Be sure to complete the connectivity task once you’re done.
                connectivityTask.setTaskCompletedWithSnapshot(false)
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                // Be sure to complete the URL session task once you’re done.
                urlSessionTask.setTaskCompletedWithSnapshot(false)
            case let relevantShortcutTask as WKRelevantShortcutRefreshBackgroundTask:
                // Be sure to complete the relevant-shortcut task once you're done.
                relevantShortcutTask.setTaskCompletedWithSnapshot(false)
            case let intentDidRunTask as WKIntentDidRunRefreshBackgroundTask:
                // Be sure to complete the intent-did-run task once you're done.
                intentDidRunTask.setTaskCompletedWithSnapshot(false)
            default:
                // make sure to complete unhandled task types
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }

    func getRemoteClockUUIDAfterLoginFromLocalStorage() -> UUID? {
        guard let uuid = UserDefaults.standard.object(forKey: "remoteClockUUID") as? String else {
            return nil
        }

        return UUID(uuidString: uuid)
    }
}
