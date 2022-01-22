//
//  ExtensionDelegate.swift
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

class ExtensionDelegate: NSObject, WKExtensionDelegate {

    let syncWithCloud = true // True to sync with ParseServer, False to Sync with iOS Phone
    private lazy var phone = OCKWatchConnectivityPeer()
    var store: OCKStore!
    private var parse: ParseRemote!
    private var sessionDelegate: SessionDelegate!
    private(set) var storeManager: OCKSynchronizedStoreManager!

    func applicationDidFinishLaunching() {

        // Parse-server setup
        PCKUtility.setupServer()

        // If the user isn't logged in, log them in
        if User.current != nil {
            // swiftlint:disable:next line_length
            self.setupRemotes(uuid: UserDefaults.standard.object(forKey: Constants.parseRemoteClockIDKey) as? String) // Setup for getting info
            NotificationCenter.default.post(.init(name: Notification.Name(rawValue: Constants.userLoggedIn)))
            Logger.extensionDelegate.info("User is already signed in...")
            store.synchronize { error in
                let errorString = error?.localizedDescription ?? "Successful sync with Cloud!"
                Logger.extensionDelegate.info("\(errorString)")
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
            if syncWithCloud {
                guard let uuid = uuid,
                      let remotUUID = UUID(uuidString: uuid) else {
                          Logger.extensionDelegate.error("Couldn't get remote clock UUID from User defaults")
                          sessionDelegate = CloudSyncSessionDelegate(store: nil)
                          WCSession.default.delegate = sessionDelegate
                          WCSession.default.activate()
                          return
                }
                parse = try ParseRemote(uuid: remotUUID, auto: true, subscribeToServerUpdates: true)
                store = OCKStore(name: "WatchParseStore", remote: parse)
                storeManager = OCKSynchronizedStoreManager(wrapping: store)

                parse?.parseRemoteDelegate = self
                sessionDelegate = CloudSyncSessionDelegate(store: store)
            } else {
                store = OCKStore(name: "PhoneStore", remote: phone)
                storeManager = OCKSynchronizedStoreManager(wrapping: store)

                phone.delegate = self
                sessionDelegate = LocalSyncSessionDelegate(remote: phone, store: store)
            }

            WCSession.default.delegate = sessionDelegate
            WCSession.default.activate()
            NotificationCenter.default.post(.init(name: Notification.Name(rawValue: Constants.storeInitialized)))

        } catch {
            Logger.extensionDelegate.error("Error setting up remote: \(error.localizedDescription)")
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

extension ExtensionDelegate: ParseRemoteDelegate {
    func didRequestSynchronization(_ remote: OCKRemoteSynchronizable) {
        store?.synchronize { error in
            let errorString = error?.localizedDescription ?? "Successful sync with Cloud!"
            Logger.extensionDelegate.info("\(errorString)")
        }
    }

    func successfullyPushedDataToCloud() {
        Logger.extensionDelegate.info("Finished pusshing data.")
    }

    func remote(_ remote: OCKRemoteSynchronizable, didUpdateProgress progress: Double) {
        Logger.extensionDelegate.info("Synchronization completed: \(progress)")
    }

    func chooseConflictResolution(conflicts: [OCKEntity], completion: @escaping OCKResultClosure<OCKEntity>) {

        // https://github.com/carekit-apple/CareKit/issues/567
        // Workaround to handle deleted and re-added outcomes.
        // Always prefer updates over deletes.
        let outcomes = conflicts.compactMap { conflict -> OCKOutcome? in
            if case let .outcome(outcome) = conflict {
                return outcome
            } else {
                return nil
            }
        }

        if outcomes.count == 2,
           outcomes.contains(where: { $0.deletedDate != nil}),
           let added = outcomes.first(where: { $0.deletedDate == nil}) {

            completion(.success(.outcome(added)))
            return
        }

        if let first = conflicts.first {
            completion(.success(first))
        } else {
            completion(.failure(.remoteSynchronizationFailed(reason: "Error, non selected for conflict")))
        }
    }
}

protocol SessionDelegate: WCSessionDelegate {}

private class CloudSyncSessionDelegate: NSObject, SessionDelegate {
    var store: OCKStore?

    init(store: OCKStore?) {
        self.store = store
    }

    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {

        switch activationState {
        case .activated:

            DispatchQueue.main.async {
                // If user isn't logged in, request login from iPhone
                if User.current == nil {
                    // swiftlint:disable:next line_length
                    WCSession.default.sendMessage([Constants.parseUserSessionTokenKey: Constants.parseUserSessionTokenKey],
                                                  replyHandler: { reply in
                        Task {
                            await LoginViewModel.loginFromiPhoneMessage(reply)
                        }
                    }) { error in // swiftlint:disable:this multiple_closures_with_trailing_closure
                        Logger.watch.error("(error)")
                    }
                }
            }
        default:
            Logger.watch.info("None supported session state: \(activationState.rawValue)")
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        if (message[Constants.parseUserSessionTokenKey] as? String) != nil {
            Task {
                await LoginViewModel.loginFromiPhoneMessage(message)
            }
        } else if (message[Constants.requestSync] as? String) != nil {
            store?.synchronize { error in
                let errorString = error?.localizedDescription ?? "Successful sync with Cloud!"
                Logger.watch.info("\(errorString)")
            }
        }
    }
}

private class LocalSyncSessionDelegate: NSObject, SessionDelegate {
    let remote: OCKWatchConnectivityPeer
    let store: OCKStore

    init(remote: OCKWatchConnectivityPeer, store: OCKStore) {
        self.remote = remote
        self.store = store
    }

    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        Logger.extensionDelegate.info("New session state: \(activationState.rawValue)")

        if activationState == .activated {
            store.synchronize { error in
                let errorString = error?.localizedDescription ?? "Successful sync with iPhone!"
                Logger.extensionDelegate.info("\(errorString)")
            }
        }
    }

    func session(_ session: WCSession,
                 didReceiveMessage message: [String: Any],
                 replyHandler: @escaping ([String: Any]) -> Void) {

        Logger.extensionDelegate.info("Received message from iPhone")
        remote.reply(to: message, store: store) { reply in
            replyHandler(reply)
        }
    }
}
