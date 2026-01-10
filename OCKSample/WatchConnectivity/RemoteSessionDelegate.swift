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
import Synchronization
import WatchConnectivity

final class RemoteSessionDelegate: NSObject, SessionDelegate, Sendable {

    let store = Mutex<OCKStore?>(nil)

    init(store: OCKStore?) {
		self.store.setValue(store)
    }

    #if os(iOS) || os(visionOS)
	func sessionDidBecomeInactive(_ session: WCSession) {
		Logger.remoteSessionDelegate.info("sessionDidBecomeInactive")
	}

	func sessionDidDeactivate(_ session: WCSession) {
		Logger.remoteSessionDelegate.info("sessionDidDeactivate")
	}
#endif

	func session(
		_ session: WCSession,
		activationDidCompleteWith activationState: WCSessionActivationState,
		error: Error?
	) {

		switch activationState {
		case .activated:
#if os(watchOS)
			Task {
				do {
					_ = try await User.current()
				} catch {
					// If user is not logged in, request login from iPhone
					let message = [
						Constants.parseUserSessionTokenKey: Constants.parseUserSessionTokenKey
					]
					WCSession.default.sendMessage(
						message,
						replyHandler: nil
					) { error in // swiftlint:disable:this multiple_closures_with_trailing_closure
						Logger.remoteSessionDelegate.error("Could not get sessionToken from iOS: \(error)")
					}
				}
			}

#else
			DispatchQueue.main.async {
				NotificationCenter.default.post(.init(name: Notification.Name(rawValue: Constants.requestSync)))
			}
#endif
		default:
			Logger.remoteSessionDelegate.info("None supported session state: \(activationState.rawValue)")
		}
	}

	func session(
		_ session: WCSession,
		didReceiveMessage message: [String: Any]
	) {
#if os(iOS)
		if (message[Constants.parseUserSessionTokenKey] as? String) != nil {
			Logger.remoteSessionDelegate.info("Received message from Apple Watch requesting session token, sending now")
			// Prepare data for watchOS, don't use reply handler as it's not Sendable.
			Task {
				do {
					let message = try await Utility.getUserSessionForWatch()
					WCSession.default.sendMessage(
						message,
						replyHandler: nil,
						errorHandler: { error in
							Logger.remoteSessionDelegate.info("Could not send session token to watch: \(error)")
						}
					)
				} catch {
					Logger.remoteSessionDelegate.info("Could not get session token for watch: \(error)")
				}
			}
		} else {
			DispatchQueue.main.async {
				NotificationCenter.default.post(
					.init(
						name: Notification.Name(rawValue: Constants.requestSync)
					)
				)
			}
		}
#elseif os(watchOS)
		if (message[Constants.parseUserSessionTokenKey] as? String) != nil {
			let sendableMessage = Utility.convertNonSendableDictionaryToSendable(message)
			Task {
				await LoginViewModel.loginFromiPhoneMessage(sendableMessage)
			}
		} else if (message[Constants.requestSync] as? String) != nil {
			store.value()?.synchronize { error in
				let errorString = error?.localizedDescription ?? "Successful sync with remote!"
				Logger.remoteSessionDelegate.info("\(errorString)")
			}
		}
#endif
	}
}
