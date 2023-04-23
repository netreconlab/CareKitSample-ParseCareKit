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

    @Published private(set) var store: OCKStore! {
        willSet {
            newValue.synchronize { error in
                let errorString = error?.localizedDescription ?? "Successful sync with remote!"
                Logger.appDelegate.info("\(errorString)")
            }
            self.objectWillChange.send()
        }
    }
    private(set) var parseRemote: ParseRemote!

    // MARK: Private read/write properties

    private var sessionDelegate: SessionDelegate!
    private lazy var phoneRemote = OCKWatchConnectivityPeer()

    func applicationDidFinishLaunching() {
        Task {
            if isSyncingWithRemote {
                do {
                    // Parse-server setup
                    try await PCKUtility.setupServer(fileName: Constants.parseConfigFileName) { _, completionHandler in
                        completionHandler(.performDefaultHandling, nil)
                    }
                    await Utility.clearDeviceOnFirstRun()
                    do {
                        _ = try await User.current()
                        do {
                            let uuid = try await Utility.getRemoteClockUUID()
                            try await self.setupRemotes(uuid: uuid)
                            Logger.appDelegate.info("User is already signed in...")
                        } catch {
                            Logger.appDelegate.error("User is logged in, but missing remoteId: \(error)")
                            try await setupRemotes(uuid: nil)
                        }
                        parseRemote.automaticallySynchronizes = true
                    } catch {
                        Logger.appDelegate.info("User is not logged in...")
                        try await setupRemotes(uuid: nil)
                    }
                } catch {
                    Logger.appDelegate.info("Could not configure Parse Swift: \(error)")
                }
            } else {
                await Utility.clearDeviceOnFirstRun()
                do {
                    try await self.setupRemotes()
                    phoneRemote.automaticallySynchronizes = true
                } catch {
                    Logger.appDelegate.error("""
                        Could not populate
                        data stores: \(error)
                    """)
                }
            }
        }
    }

    func didRegisterForRemoteNotifications(withDeviceToken deviceToken: Data) {
        Task {
            await Utility.updateInstallationWithDeviceToken(deviceToken)
        }
    }

    @MainActor
    func setupRemotes(uuid: UUID? = nil) async throws {
        do {
            if isSyncingWithRemote {
                if sessionDelegate == nil {
                    sessionDelegate = RemoteSessionDelegate(store: store)
                    WCSession.default.delegate = sessionDelegate
                }
                guard let uuid = uuid else {
                    Logger.appDelegate.error("Could not get remote clock UUID")
                    WCSession.default.activate()
                    return
                }
                parseRemote = try await ParseRemote(uuid: uuid,
                                                    auto: false,
                                                    subscribeToServerUpdates: true,
                                                    defaultACL: PCKUtility.getDefaultACL())
                let store = OCKStore(name: Constants.watchOSParseCareStoreName,
                                     type: .onDisk(),
                                     remote: parseRemote)
                parseRemote?.parseRemoteDelegate = self
                sessionDelegate.store = store
                self.store = store
            } else {
                let store = OCKStore(name: Constants.watchOSLocalCareStoreName,
                                     type: .onDisk(),
                                     remote: phoneRemote)
                phoneRemote.delegate = self
                sessionDelegate = LocalSessionDelegate(remote: phoneRemote,
                                                       store: store)
                WCSession.default.delegate = sessionDelegate
                self.store = store
            }
            WCSession.default.activate()
        } catch {
            Logger.appDelegate.error("Error setting up remote: \(error)")
            throw error
        }
    }

    @MainActor
    func resetAppToInitialState() {

        do {
            try self.store?.delete()
        } catch {
            Logger.appDelegate.error("Error deleting OCKStore: \(error)")
        }

        parseRemote = nil

        let store = OCKStore(name: Constants.noCareStoreName,
                             type: .inMemory)
        sessionDelegate.store = store
        self.store = store
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
