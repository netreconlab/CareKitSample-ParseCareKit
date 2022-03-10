//
//  ColorStyle.swift
//  OCKSample
//
//  Created by Corey Baker on 10/16/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import CareKitUI
import UIKit

struct ColorStyle: OCKColorStyler {
    #if os(iOS)
    var label: UIColor {
        FontColorKey.defaultValue
    }
    var tertiaryLabel: UIColor {
        TintColorKey.defaultValue
    }
    #endif
}
