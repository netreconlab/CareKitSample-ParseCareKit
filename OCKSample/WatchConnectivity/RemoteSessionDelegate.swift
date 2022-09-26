//
//  RemoteSessionDelegate.swift
//  OCKSample
//
//  Created by Corey Baker on 2/26/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import CareKitStore
import Foundation
import os.log
import WatchConnectivity

class RemoteSessionDelegate: NSObject, SessionDelegate {

    var store: OCKStore?

    init(store: OCKStore?) {
        self.store = store
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        Logger.remoteSessionDelegate.info("sessionDidBecomeInactive")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        Logger.remoteSessionDelegate.info("sessionDidDeactivate")
    }
    #endif

    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {

        switch activationState {
        case .activated:
            #if os(watchOS)

            DispatchQueue.main.async {
                // If user is not logged in, request login from iPhone
                if User.current == nil {
                    // swiftlint:disable:next line_length
                    WCSession.default.sendMessage([Constants.parseUserSessionTokenKey: Constants.parseUserSessionTokenKey],
                                                  replyHandler: { reply in
                        Task {
                            await LoginViewModel.loginFromiPhoneMessage(reply)
                        }
                    }) { error in // swiftlint:disable:this multiple_closures_with_trailing_closure
                        Logger.remoteSessionDelegate.error("Could not get sessionToken from iOS: \(error)")
                    }
                }
            }

            #else
            if activationState == .activated {
                NotificationCenter.default.post(.init(name: Notification.Name(rawValue: Constants.requestSync)))
            }
            #endif
        default:
            Logger.remoteSessionDelegate.info("None supported session state: \(activationState.rawValue)")
        }

    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        #if os(watchOS)
        if (message[Constants.parseUserSessionTokenKey] as? String) != nil {
            Task {
                await LoginViewModel.loginFromiPhoneMessage(message)
            }
        } else if (message[Constants.requestSync] as? String) != nil {
            store?.synchronize { error in
                let errorString = error?.localizedDescription ?? "Successful sync with remote!"
                Logger.remoteSessionDelegate.info("\(errorString)")
            }
        }
        #else
        NotificationCenter.default.post(.init(name: Notification.Name(rawValue: Constants.requestSync)))
        #endif
    }

    func session(_ session: WCSession,
                 didReceiveMessage message: [String: Any],
                 replyHandler: @escaping ([String: Any]) -> Void) {
        #if os(iOS)
        if (message[Constants.parseUserSessionTokenKey] as? String) != nil {
            Logger.remoteSessionDelegate.info("Received message from Apple Watch requesting ParseUser, sending now")
            // Prepare data for watchOS
            let returnMessage = Utility.getUserSessionForWatch()
            DispatchQueue.main.async {
                replyHandler(returnMessage)
            }
        }
        #endif
    }
}
