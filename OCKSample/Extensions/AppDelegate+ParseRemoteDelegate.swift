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

extension AppDelegate: ParseRemoteDelegate {

    func didRequestSynchronization(_ remote: OCKRemoteSynchronizable) {
        NotificationCenter.default.post(.init(name: Notification.Name(rawValue: Constants.requestSync)))
    }

    func successfullyPushedDataToCloud() {
        if self.isFirstAppOpen {
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
