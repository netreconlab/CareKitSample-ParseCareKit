//
//  AppDelegate+ParseRemoteDelegate.swift
//  OCKSample
//
//  Created by Corey Baker on 9/18/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import UIKit
import CareKitStore
import ParseCareKit
import WatchConnectivity

extension AppDelegate: ParseRemoteDelegate {

	nonisolated func didRequestSynchronization(_ remote: OCKRemoteSynchronizable) {
		NotificationCenter.default.post(.init(name: Notification.Name(rawValue: Constants.requestSync)))
	}

	nonisolated func successfullyPushedToRemote() {
		DispatchQueue.main.async { [weak self] in
			guard let self else { return }
			if self.isFirstTimeLogin {
				self.setFirstTimeLogin(false)
			}
		}
#if !targetEnvironment(simulator)
		// watchOS 9 needs to be sent messages for updates on real devices
		if isSendingPushUpdatesToWatch {
			let message = Utility.prepareSyncMessageForWatch()
			WCSession.default.sendMessage(
				message,
				replyHandler: nil,
				errorHandler: { error in
					Logger.remoteSessionDelegate.info("Could not send sync notification to watch: \(error)")
				}
			)
		}
#endif
	}

	nonisolated func provideStore() -> OCKAnyStoreProtocol {
		return StoreCoordinatorKey.defaultValue
	}

	nonisolated func remote(
		_ remote: OCKRemoteSynchronizable,
		didUpdateProgress progress: Double
	) {
		let progressPercentage = Int(progress * 100.0)
		NotificationCenter.default.post(
			.init(
				name: Notification.Name(
					rawValue: Constants.progressUpdate
				),
				userInfo: [Constants.progressUpdate: progressPercentage]
			)
		)
	}

	nonisolated func chooseConflictResolution(
		conflicts: [OCKEntity],
		completion: @escaping OCKResultClosure<OCKEntity>
	) {
        // https://github.com/carekit-apple/CareKit/issues/567
        // Last write wins
        do {
			let lastWrite = try conflicts
				.max(
					by: {
						try $0.parseEntity().value.createdDate! > $1.parseEntity().value.createdDate!
					}
				)!

            completion(.success(lastWrite))
        } catch {
			completion(
				.failure(
					.invalidValue(
						reason: error.localizedDescription
					)
				)
			)
        }
    }
}
