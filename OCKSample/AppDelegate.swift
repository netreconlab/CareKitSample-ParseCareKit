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

class AppDelegate: UIResponder, UIApplicationDelegate, ObservableObject {

    let isSyncingWithCloud = true // True to sync with ParseServer, False to Sync with iOS Watch
    var isFirstAppOpen = true
    var isFirstLogin = false
    private var sessionDelegate: SessionDelegate!
    private lazy var watch = OCKWatchConnectivityPeer()
    private(set) var parseRemote: ParseRemote!
    @Published private(set) var profileViewModel = ProfileViewModel() {
        willSet {
            ProfileViewModelKey.defaultValue = newValue
        }
    }
    private(set) var store: OCKStore?
    // swiftlint:disable:next line_length
    @Published private(set) var storeManager: OCKSynchronizedStoreManager = .init(wrapping: OCKStore(name: Constants.noCareStoreName,
                                                                                                     type: .inMemory)) {
        willSet {
            StoreManagerKey.defaultValue = newValue
            DispatchQueue.main.async {
                NotificationCenter.default.post(.init(name: Notification.Name(rawValue: Constants.storeInitialized)))
            }
        }
    }
    private(set) var healthKitStore: OCKHealthKitPassthroughStore!

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Parse-server setup
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

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
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
            try store?.delete() // Delete data in local OCKStore database
        } catch {
            Logger.appDelegate.error("Error deleting OCKStore: \(error.localizedDescription)")
        }
        isFirstAppOpen = true
        isFirstLogin = true
        storeManager = .init(wrapping: OCKStore(name: Constants.noCareStoreName, type: .inMemory))
        healthKitStore = nil
        parseRemote = nil
        store = nil
    }

    func setupRemotes(uuid: UUID? = nil) {
        do {

            if isSyncingWithCloud {
                guard let uuid = uuid else {
                    Logger.appDelegate.error("Error in setupRemotes, uuid is nil")
                    return
                }
                parseRemote = try ParseRemote(uuid: uuid,
                                              auto: false,
                                              subscribeToServerUpdates: true,
                                              defaultACL: try? ParseACL.defaultACL())
                store = OCKStore(name: Constants.iOSParseCareStoreName,
                                 type: .onDisk(),
                                 remote: parseRemote)
                parseRemote?.parseRemoteDelegate = self
                sessionDelegate = RemoteSessionDelegate(store: store)
            } else {
                store = OCKStore(name: Constants.iOSLocalCareStoreName,
                                 type: .onDisk(),
                                 remote: watch)
                watch.delegate = self
                sessionDelegate = LocalSessionDelegate(remote: watch, store: store)
            }

            WCSession.default.delegate = sessionDelegate
            WCSession.default.activate()

            guard let currentStore = store else {
                return
            }
            healthKitStore = OCKHealthKitPassthroughStore(store: currentStore)
            let coordinator = OCKStoreCoordinator()
            coordinator.attach(store: currentStore)
            coordinator.attach(eventStore: healthKitStore)
            storeManager = OCKSynchronizedStoreManager(wrapping: coordinator)
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
