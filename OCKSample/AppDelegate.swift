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

    @Published var isFirstTimeLogin = false

    // MARK: Public read private write properties

    @Published private(set) var storeCoordinator: OCKStoreCoordinator = .init() {
        willSet {
            StoreCoordinatorKey.defaultValue = newValue
            self.objectWillChange.send()
        }
    }
    @Published private(set) var store: OCKStore! = .init(name: Constants.noCareStoreName, type: .inMemory)
    private(set) var healthKitStore: OCKHealthKitPassthroughStore!
    private(set) var parseRemote: ParseRemote!

    // MARK: Private read/write properties

    private var sessionDelegate: SessionDelegate!
    private lazy var watchRemote = OCKWatchConnectivityPeer()

    // MARK: Helpers

    @MainActor
    func resetAppToInitialState() {
        do {
            try storeCoordinator.reset()
        } catch {
            Logger.appDelegate.error("Could not delete Coordinator Store: \(error)")
        }

        do {
            try self.store?.delete()
        } catch {
            Logger.utility.error("Could not delete local OCKStore because of error: \(error)")
        }

        storeCoordinator = .init()
        healthKitStore = nil
        parseRemote = nil

        let store = OCKStore(name: Constants.noCareStoreName,
                             type: .inMemory)
        sessionDelegate.store = store
        self.store = store
    }

    @MainActor
    func setupRemotes(uuid: UUID? = nil) async throws {
        do {
            if isSyncingWithCloud {
                guard let uuid = uuid else {
                    Logger.appDelegate.error("Could not setupRemotes, uuid is nil")
                    return
                }
                parseRemote = try await ParseRemote(uuid: uuid,
                                                    auto: false,
                                                    subscribeToServerUpdates: true,
                                                    defaultACL: try? ParseACL.defaultACL())
                let store = OCKStore(name: Constants.iOSParseCareStoreName,
                                     type: .onDisk(),
                                     remote: parseRemote)
                parseRemote?.parseRemoteDelegate = self
                sessionDelegate = RemoteSessionDelegate(store: store)
                self.store = store
            } else {
                let store = OCKStore(name: Constants.iOSLocalCareStoreName,
                                 type: .onDisk(),
                                 remote: watchRemote)
                watchRemote.delegate = self
                sessionDelegate = LocalSessionDelegate(remote: watchRemote, store: store)
                self.store = store
            }

            // Setup communication with watch
            WCSession.default.delegate = sessionDelegate
            WCSession.default.activate()

            healthKitStore = OCKHealthKitPassthroughStore(store: store)
            let storeCoordinator = OCKStoreCoordinator()
            storeCoordinator.attach(store: store)
            storeCoordinator.attach(eventStore: healthKitStore)
            self.storeCoordinator = storeCoordinator
        } catch {
            Logger.appDelegate.error("Could not setup remote: \(error)")
            throw error
        }
    }
}
