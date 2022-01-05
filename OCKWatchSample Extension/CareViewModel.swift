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

@MainActor
class CareViewModel: ObservableObject {
    @Published var isOnboarded = false
    @Published var update = false
    private var cancellables: Set<AnyCancellable> = []

    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(reloadViewModel),
                                               name: Notification.Name(rawValue: Constants.storeIsInitialized),
                                               object: nil)
        Task {
            await checkIfOnboardingIsComplete()
        }
    }

    // MARK: Helpers

    private func observeTask(_ task: OCKTask) {

        StoreManagerKey.defaultValue?.publisher(forEventsBelongingToTask: task,
                                                categories: [OCKStoreNotificationCategory.add,
                                                             OCKStoreNotificationCategory.update,
                                                             OCKStoreNotificationCategory.delete])
            .sink { [weak self] in
                guard let current = self else { return }
                Logger.feed.info("Onboarding updated: \($0, privacy: .private)")
                Task {
                    await current.checkIfOnboardingIsComplete()
                }
            }
            .store(in: &cancellables)
    }

    private func clearSubscriptions() {
        cancellables = []
    }

    @objc private func reloadViewModel() {
        Task {
            await checkIfOnboardingIsComplete()
        }
    }

    func checkIfOnboardingIsComplete() async {
        self.isOnboarded = true
    }
}
