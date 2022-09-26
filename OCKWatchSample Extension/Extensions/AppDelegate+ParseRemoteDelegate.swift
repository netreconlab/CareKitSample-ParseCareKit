//
//  AppDelegate+ParseRemoteDelegate.swift
//  OCKSample
//
//  Created by Corey Baker on 9/18/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import CareKit
import CareKitStore
import ParseCareKit
import os.log

extension AppDelegate: ParseRemoteDelegate {
    func didRequestSynchronization(_ remote: OCKRemoteSynchronizable) {
        store?.synchronize { error in
            let errorString = error?.localizedDescription ?? "Successful sync with remote!"
            Logger.appDelegate.info("\(errorString)")
        }
    }

    func successfullyPushedDataToCloud() {
        Logger.appDelegate.info("Finished pushing data.")
    }

    func remote(_ remote: OCKRemoteSynchronizable, didUpdateProgress progress: Double) {}

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
