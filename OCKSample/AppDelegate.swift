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

class AppDelegate: UIResponder, ObservableObject {
    // MARK: Public read/write properties
    var isFirstTimeLogin = false

    // MARK: Public read private write properties
    // swiftlint:disable:next line_length
    @Published private(set) var storeManager: OCKSynchronizedStoreManager = .init(wrapping: OCKStore(name: Constants.noCareStoreName,
                                                                                                     type: .inMemory)) {
        willSet {
            StoreManagerKey.defaultValue = newValue
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    private(set) var parseRemote: ParseRemote!
    private(set) var store: OCKStore?
    private(set) var healthKitStore: OCKHealthKitPassthroughStore!

    // MARK: Private read/write properties
    private var sessionDelegate: SessionDelegate!
    private lazy var watchRemote = OCKWatchConnectivityPeer()

    // MARK: Helpers
    func resetAppToInitialState() {
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
        storeManager = .init(wrapping: OCKStore(name: Constants.noCareStoreName, type: .inMemory))
        healthKitStore = nil
        parseRemote = nil
        store = nil
        sessionDelegate.store = store
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
                                 remote: watchRemote)
                watchRemote.delegate = self
                sessionDelegate = LocalSessionDelegate(remote: watchRemote, store: store)
            }

            // Setup communication with watch
            WCSession.default.delegate = sessionDelegate
            WCSession.default.activate()

            guard let currentStore = store else {
                Logger.appDelegate.error("Should have OCKStore")
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
