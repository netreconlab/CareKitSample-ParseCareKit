//
//  CareViewModel.swift
//  OCKSample
//
//  Created by Corey Baker on 1/7/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import Foundation

class CareViewModel: ObservableObject {
    @Published var update = false

    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(reloadViewModel),
                                               name: Notification.Name(rawValue: Constants.storeInitialized),
                                               object: nil)
    }

    // MARK: Helpers

    @objc private func reloadViewModel() {
        update = !update
    }
}
