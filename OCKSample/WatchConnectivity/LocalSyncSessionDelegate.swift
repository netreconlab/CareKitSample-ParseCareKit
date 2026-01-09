//
//  LocalSyncSessionDelegate.swift
//  OCKSample
//
//  Created by Corey Baker on 2/26/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import CareKitStore
import Foundation
import os.log
import Synchronization
import WatchConnectivity

@MainActor
class LocalSessionDelegate: NSObject, @MainActor SessionDelegate {
    let remote: OCKWatchConnectivityPeer
	let store = Mutex<OCKStore?>(nil)

    init(remote: OCKWatchConnectivityPeer, store: OCKStore?) {
        self.remote = remote
		self.store.setValue(store)
    }

    #if os(iOS) || os(visionOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        Logger.localSessionDelegate.info("sessionDidBecomeInactive")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        Logger.localSessionDelegate.info("sessionDidDeactivate")
    }
    #endif

    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        Logger.localSessionDelegate.info("New session state: \(activationState.rawValue)")
        if activationState == .activated {
            #if os(watchOS)
			store.value()?.synchronize { error in
                let errorString = error?.localizedDescription ?? "Successful sync with iPhone!"
                Logger.localSessionDelegate.info("\(errorString)")
            }
            #else
            NotificationCenter.default.post(.init(name: Notification.Name(rawValue: Constants.requestSync)))
            #endif
        }
    }

    func session(_ session: WCSession,
                 didReceiveMessage message: [String: Any],
                 replyHandler: @escaping ([String: Any]) -> Void) {
        #if os(watchOS)
        Logger.localSessionDelegate.info("Received message from iPhone")
		guard let store = store.value() else {
            return
        }
        remote.reply(to: message, store: store) { reply in
            DispatchQueue.main.async {
                replyHandler(reply)
            }
        }
        #else
        if (message[Constants.parseUserSessionTokenKey] as? String) != nil {
            Logger.localSessionDelegate.info("Received message from Apple Watch requesting ParseUser, sending now")

			Task {
                do {
                    // Prepare data for watchOS
					let returnMessage = try await Utility.getUserSessionForWatch()
                    DispatchQueue.main.async {
                        replyHandler(returnMessage)
                    }
                } catch {
                    Logger.localSessionDelegate.info("Could not get session for watch: \(error)")
                }
            }
        } else {
            DispatchQueue.main.async {
                NotificationCenter.default.post(.init(name: Notification.Name(rawValue: Constants.requestSync)))
            }
        }
        #endif
    }
}
