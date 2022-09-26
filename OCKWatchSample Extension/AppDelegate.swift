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
    // MARK: Public read private write properties
    @Published private(set) var storeManager: OCKSynchronizedStoreManager! {
        willSet {
            StoreManagerKey.defaultValue = newValue
            DispatchQueue.main.async {
                NotificationCenter.default.post(.init(name: Notification.Name(rawValue: Constants.storeInitialized)))
                self.objectWillChange.send()
            }
        }
    }
    private(set) var store: OCKStore!
    private(set) var parseRemote: ParseRemote!

    // MARK: Private read/write properties
    private var sessionDelegate: SessionDelegate!
    private lazy var phoneRemote = OCKWatchConnectivityPeer()

    func applicationDidFinishLaunching() {
        // Parse-server setup
        PCKUtility.setupServer(fileName: Constants.parseConfigFileName) { _, completionHandler in
            completionHandler(.performDefaultHandling, nil)
        }

        if User.current != nil {
            do {
                let uuid = try Utility.getRemoteClockUUID()
                self.setupRemotes(uuid: uuid)
                parseRemote.automaticallySynchronizes = true
                NotificationCenter.default.post(.init(name: Notification.Name(rawValue: Constants.userLoggedIn)))
                Logger.appDelegate.info("User is already signed in...")
                store.synchronize { error in
                    let errorString = error?.localizedDescription ?? "Successful sync with remote!"
                    Logger.appDelegate.info("\(errorString)")
                }
            } catch {
                Logger.appDelegate.error("User is logged in, but missing remoteId: \(error)")
                setupRemotes(uuid: nil)
            }
        } else {
            Logger.appDelegate.info("User is not logged in...")
            setupRemotes(uuid: nil)
        }
    }

    func didRegisterForRemoteNotifications(withDeviceToken deviceToken: Data) {
        Task {
            await Utility.updateInstallationWithDeviceToken(deviceToken)
        }
    }

    func setupRemotes(uuid: UUID? = nil) {
        do {
            if isSyncingWithCloud {
                if sessionDelegate == nil {
                    sessionDelegate = RemoteSessionDelegate(store: store)
                    WCSession.default.delegate = sessionDelegate
                }
                guard let uuid = uuid else {
                    Logger.appDelegate.error("Could not get remote clock UUID")
                    WCSession.default.activate()
                    return
                }
                parseRemote = try ParseRemote(uuid: uuid,
                                              auto: false,
                                              subscribeToServerUpdates: true)
                store = OCKStore(name: Constants.watchOSParseCareStoreName,
                                 remote: parseRemote)
                parseRemote?.parseRemoteDelegate = self
                sessionDelegate.store = store
                storeManager = OCKSynchronizedStoreManager(wrapping: store)
            } else {
                store = OCKStore(name: Constants.watchOSLocalCareStoreName,
                                 remote: phoneRemote)
                phoneRemote.delegate = self
                sessionDelegate = LocalSessionDelegate(remote: phoneRemote, store: store)
                WCSession.default.delegate = sessionDelegate
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
}
