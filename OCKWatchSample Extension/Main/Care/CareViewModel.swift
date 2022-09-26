//
//  CareViewModel.swift
//  OCKWatchSample Extension
//
//  Created by Corey Baker on 1/5/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import Combine
import CareKit
import CareKitStore
import WatchConnectivity
import os.log

class CareViewModel: ObservableObject {
    // MARK: Public read, private write properties
    @Published private(set) var storeManager: OCKSynchronizedStoreManager {
        didSet {
            synchronizeStore()
        }
    }

    // MARK: Private read/private write properties
    private var cancellables: Set<AnyCancellable> = []

    init(storeManager: OCKSynchronizedStoreManager? = nil) {
        self.storeManager = storeManager ?? StoreManagerKey.defaultValue
        NotificationCenter.default.addObserver(self, selector: #selector(reloadViewModel),
                                               name: Notification.Name(rawValue: Constants.storeInitialized),
                                               object: nil)
        synchronizeStore()
    }

    // MARK: Helpers (private)
    @MainActor
    @objc private func reloadViewModel() {
        let updatedStoreManager = StoreManagerKey.defaultValue
        guard storeManager !== updatedStoreManager else {
            return
        }
        storeManager = updatedStoreManager
    }

    private func synchronizeStore() {
        guard let store = storeManager.store as? OCKStore else {
            return
        }
        store.synchronize { error in
            let errorString = error?.localizedDescription ?? "Successful sync with remote!"
            Logger.feed.info("\(errorString)")
        }
    }
}
