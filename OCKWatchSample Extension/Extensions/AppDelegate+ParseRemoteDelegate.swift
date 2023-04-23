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

    func successfullyPushedToRemote() {
        Logger.appDelegate.info("Finished pushing data")
    }

    func needStore() -> OCKAnyStoreProtocol {
        guard let store = store else {
            return OCKStore(name: Constants.noCareStoreName, type: .inMemory)
        }
        return store
    }

    func remote(_ remote: OCKRemoteSynchronizable, didUpdateProgress progress: Double) {}

    func chooseConflictResolution(conflicts: [OCKEntity], completion: @escaping OCKResultClosure<OCKEntity>) {

        // https://github.com/carekit-apple/CareKit/issues/567
        // Last write wins
        do {
            let lastWrite = try conflicts
                .max(by: { try $0.parseEntity().value.createdDate! > $1.parseEntity().value.createdDate! })!

            completion(.success(lastWrite))
        } catch {
            completion(.failure(.invalidValue(reason: error.localizedDescription)))
        }
    }
}
