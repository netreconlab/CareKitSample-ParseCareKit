//
//  SessionDelegate.swift
//  OCKSample
//
//  Created by Corey Baker on 2/26/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import CareKitStore
import Foundation
import WatchConnectivity

protocol SessionDelegate: WCSessionDelegate {
    var store: OCKStore? { get set }
}
