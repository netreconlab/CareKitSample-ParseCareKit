//
//  TintColorFlipKey.swift
//  OCKSample
//
//  Created by Corey Baker on 9/26/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import SwiftUI

struct TintColorFlipKey: EnvironmentKey {
    static var defaultValue: UIColor {
        #if os(iOS) || os(visionOS)
        return UIColor { $0.userInterfaceStyle == .light ? #colorLiteral(red: 1, green: 0.8, blue: 0.1176470593, alpha: 1) : #colorLiteral(red: 0.6000000238, green: 0.1058823541, blue: 0.1176470593, alpha: 1) }
        #else
        return #colorLiteral(red: 1, green: 0.8, blue: 0.1176470593, alpha: 1)
        #endif
    }
}

extension EnvironmentValues {
    var tintColorFlip: UIColor {
        self[TintColorFlipKey.self]
    }
}
