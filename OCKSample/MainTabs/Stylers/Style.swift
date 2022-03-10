//
//  Style.swift
//  OCKSample
//
//  Created by Corey Baker on 10/16/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import CareKitUI

struct Style: OCKStyler {
    var color: OCKColorStyler {
        ColorStyle()
    }
    var dimension: OCKDimensionStyler {
        OCKDimensionStyle()
    }
    var animation: OCKAnimationStyler {
        OCKAnimationStyle()
    }
    var appearance: OCKAppearanceStyler {
        OCKAppearanceStyle()
    }
}
