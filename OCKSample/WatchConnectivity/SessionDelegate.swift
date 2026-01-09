//
//  SessionDelegate.swift
//  OCKSample
//
//  Created by Corey Baker on 2/26/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import CareKitStore
import Foundation
import Synchronization
import WatchConnectivity

protocol SessionDelegate: WCSessionDelegate {
    var store: Mutex<OCKStore?> { get }
}
