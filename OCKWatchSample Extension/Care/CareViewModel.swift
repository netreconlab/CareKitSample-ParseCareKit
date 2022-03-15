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
    @Published var update = false
    @Published var storeManager: OCKSynchronizedStoreManager
    private var cancellables: Set<AnyCancellable> = []

    init() {
        storeManager = StoreManagerKey.defaultValue ?? .init(wrapping: OCKStore(name: "none", type: .inMemory))
        NotificationCenter.default.addObserver(self, selector: #selector(reloadViewModel),
                                               name: Notification.Name(rawValue: Constants.storeInitialized),
                                               object: nil)
    }

    // MARK: Helpers

    private func observeTask(_ task: OCKTask) {

        storeManager.publisher(forEventsBelongingToTask: task,
                               categories: [OCKStoreNotificationCategory.add,
                                            OCKStoreNotificationCategory.update,
                                            OCKStoreNotificationCategory.delete])
            .sink { [weak self] in
                guard self != nil else { return }
                Logger.feed.info("Task updated: \($0, privacy: .private)")
            }
            .store(in: &cancellables)
    }

    private func clearSubscriptions() {
        cancellables = []
    }

    @objc private func reloadViewModel() {
        guard let storeManager = StoreManagerKey.defaultValue,
              self.storeManager !== storeManager else {
            return
        }
        self.clearSubscriptions()
        self.storeManager = storeManager
    }

    // MARK: Intents

    func synchronizeStore() {
        guard let store = storeManager.store as? OCKStore else {
            return
        }
        store.synchronize { error in
            let errorString = error?.localizedDescription ?? "Successful sync with remote!"
            Logger.feed.info("\(errorString)")
        }
    }
}
