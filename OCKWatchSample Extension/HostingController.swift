//
//  HostingController.swift
//  OCKWatchSample Extension
//
//  Created by Corey Baker on 6/25/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
//

import WatchKit
import Foundation
import SwiftUI

class HostingController: WKHostingController<CareView> {
    override var body: CareView {
        CareView()
    }
}
