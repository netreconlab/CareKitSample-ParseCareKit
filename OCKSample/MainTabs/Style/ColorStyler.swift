//
//  ColorStyler.swift
//  OCKSample
//
//  Created by Corey Baker on 10/16/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import CareKitUI
import UIKit

struct ColorStyler: OCKColorStyler {
    #if iOS
    var label: UIColor {
        FontColorKey.defaultValue
    }
    var tertiaryCustomFill: UIColor {
        TintColorKey.defaultValue
    }
    #endif
}
