//
//  WatchAppViewModel.swift
//  OCKWatchSample
//
//  Created by Corey Baker on 8/29/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import CareKit
import CareKitStore
import ParseCareKit
import ParseSwift
import WatchKit
import WatchConnectivity
import os.log

class WatchAppViewModel: ObservableObject {
    let syncWithCloud = true // True to sync with ParseServer, False to Sync with iOS Phone
    private var parseRemote: ParseRemote!
    private var sessionDelegate: SessionDelegate!
    private lazy var phone = OCKWatchConnectivityPeer()
    private(set) var store: OCKStore!
    private(set) var storeManager: OCKSynchronizedStoreManager!

}
