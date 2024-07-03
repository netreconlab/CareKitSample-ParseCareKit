//
//  TintColorKey.swift
//  OCKSample
//
//  Created by Corey Baker on 10/16/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import SwiftUI

struct TintColorKey: EnvironmentKey {
    static var defaultValue: UIColor {
        #if os(iOS)
        return UIColor { $0.userInterfaceStyle == .light ? #colorLiteral(red: 0.6000000238, green: 0.1058823541, blue: 0.1176470593, alpha: 1) : #colorLiteral(red: 1, green: 0.8, blue: 0.1176470593, alpha: 1) }
        #else
        return #colorLiteral(red: 0.6000000238, green: 0.1058823541, blue: 0.1176470593, alpha: 1)
        #endif
    }
}

extension EnvironmentValues {
    var tintColor: UIColor {
        self[TintColorKey.self]
    }
}
