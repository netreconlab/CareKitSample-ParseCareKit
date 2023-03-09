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

    func synchronizeStore(storeManager: OCKSynchronizedStoreManager?) {
        guard let store = storeManager?.store as? OCKStore else {
            Logger.feed.info("Could not cast to OCKStore.")
            return
        }
        store.synchronize { error in
            let errorString = error?.localizedDescription ?? "Successful sync with remote!"
            Logger.feed.info("\(errorString)")
        }
    }
}
