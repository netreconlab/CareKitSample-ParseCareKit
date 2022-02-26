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
import CareKitStore
import os.log
import ParseCareKit
import ParseSwift
import UIKit
import WatchConnectivity

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    let syncWithCloud = true // True to sync with ParseServer, False to Sync with iOS Watch
    var isFirstAppOpen = true
    var isFirstLogin = false
    private var sessionDelegate: SessionDelegate!
    private lazy var watch = OCKWatchConnectivityPeer()
    private(set) var parseRemote: ParseRemote!
    private(set) var profileViewModel = ProfileViewModel()
    private(set) var store: OCKStore!
    // swiftlint:disable:next line_length
    private(set) var storeManager: OCKSynchronizedStoreManager = .init(wrapping: OCKStore(name: "none", type: .inMemory))
    private(set) var healthKitStore: OCKHealthKitPassthroughStore!

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Parse-server setup
        PCKUtility.setupServer { (_, completionHandler) in
            completionHandler(.performDefaultHandling, nil)
        }
        return true
    }

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Task {
            await Utility.updateInstallationWithDeviceToken(deviceToken)
        }
    }

    func resetAppToInitialState() {
        NotificationCenter.default.post(.init(name: Notification.Name(rawValue: Constants.storeDeinitialized)))
        do {
            try healthKitStore.reset()
        } catch {
            Logger.appDelegate.error("Error deleting HealthKit Store: \(error.localizedDescription)")
        }
        do {
            try store.delete() // Delete data in local OCKStore database
        } catch {
            Logger.appDelegate.error("Error deleting OCKStore: \(error.localizedDescription)")
        }
        isFirstAppOpen = true
        isFirstLogin = false
        storeManager = .init(wrapping: OCKStore(name: "none", type: .inMemory))
        healthKitStore = nil
        parseRemote = nil
        store = nil
    }

    func setupRemotes(uuid: UUID? = nil) {
        do {

            if syncWithCloud {
                guard let uuid = uuid else {
                    Logger.appDelegate.error("Error in setupRemotes, uuid is nil")
                    return
                }
                parseRemote = try ParseRemote(uuid: uuid,
                                              auto: false,
                                              subscribeToServerUpdates: true,
                                              defaultACL: try? ParseACL.defaultACL())
                store = OCKStore(name: "ParseStore",
                                 type: .onDisk(),
                                 remote: parseRemote)
                parseRemote?.parseRemoteDelegate = self
                sessionDelegate = CloudSyncSessionDelegate(store: store)
            } else {
                store = OCKStore(name: "WatchStore", type: .onDisk(), remote: watch)
                watch.delegate = self
                sessionDelegate = LocalSyncSessionDelegate(remote: watch, store: store)
            }

            WCSession.default.delegate = sessionDelegate
            WCSession.default.activate()

            healthKitStore = OCKHealthKitPassthroughStore(store: store)
            let coordinator = OCKStoreCoordinator()
            coordinator.attach(store: store)
            coordinator.attach(eventStore: healthKitStore)
            storeManager = OCKSynchronizedStoreManager(wrapping: coordinator)
            NotificationCenter.default.post(.init(name: Notification.Name(rawValue: Constants.storeInitialized)))
        } catch {
            Logger.appDelegate.error("Error setting up remote: \(error.localizedDescription)")
        }
    }
}

extension AppDelegate: ParseRemoteDelegate {

    func didRequestSynchronization(_ remote: OCKRemoteSynchronizable) {
        NotificationCenter.default.post(.init(name: Notification.Name(rawValue: Constants.requestSync)))
    }

    func successfullyPushedDataToCloud() {
        if self.isFirstAppOpen {
            self.isFirstLogin = false
            self.isFirstAppOpen = false
            NotificationCenter.default.post(.init(name: Notification.Name(rawValue: Constants.reloadView)))
        }
    }

    func remote(_ remote: OCKRemoteSynchronizable, didUpdateProgress progress: Double) {
        let progressPercentage = Int(progress * 100.0)
        NotificationCenter.default.post(.init(name: Notification.Name(rawValue: Constants.progressUpdate),
                                              userInfo: [Constants.progressUpdate: progressPercentage]))
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
            completion(.failure(.remoteSynchronizationFailed(reason: "Error, none selected for conflict")))
        }
    }
}

protocol SessionDelegate: WCSessionDelegate {}

private class CloudSyncSessionDelegate: NSObject, SessionDelegate {

    let store: OCKStore

    init(store: OCKStore) {
        self.store = store
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        Logger.appDelegate.info("sessionDidBecomeInactive")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        Logger.appDelegate.info("sessionDidDeactivate")
    }

    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        Logger.appDelegate.info("New session state: \(activationState.rawValue)")

        if activationState == .activated {
            NotificationCenter.default.post(.init(name: Notification.Name(rawValue: Constants.requestSync)))
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        NotificationCenter.default.post(.init(name: Notification.Name(rawValue: Constants.requestSync)))
    }

    func session(_ session: WCSession,
                 didReceiveMessage message: [String: Any],
                 replyHandler: @escaping ([String: Any]) -> Void) {

        if (message[Constants.parseUserSessionTokenKey] as? String) != nil {
            Logger.watch.info("Received message from Apple Watch requesting ParseUser, sending now")

            DispatchQueue.main.async {
                // Prepare data for watchOS
                let returnMessage = Utility.getUserSessionForWatch()
                replyHandler(returnMessage)
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

    func sessionDidBecomeInactive(_ session: WCSession) {
        Logger.appDelegate.info("sessionDidBecomeInactive")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        Logger.appDelegate.info("sessionDidDeactivate")
    }

    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        Logger.appDelegate.info("New session state: \(activationState.rawValue)")

        if activationState == .activated {
            NotificationCenter.default.post(.init(name: Notification.Name(rawValue: Constants.requestSync)))
        }
    }

    func session(_ session: WCSession,
                 didReceiveMessage message: [String: Any],
                 replyHandler: @escaping ([String: Any]) -> Void) {

        if (message[Constants.parseUserSessionTokenKey] as? String) != nil {
            Logger.watch.info("Received message from Apple Watch requesting ParseUser, sending now")

            DispatchQueue.main.async {
                // Prepare data for watchOS
                let returnMessage = Utility.getUserSessionForWatch()
                replyHandler(returnMessage)
            }
        } else {
            NotificationCenter.default.post(.init(name: Notification.Name(rawValue: Constants.requestSync)))
        }
    }
}
