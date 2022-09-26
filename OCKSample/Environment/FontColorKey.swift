//
//  FontColorKey.swift
//  OCKSample
//
//  Created by Corey Baker on 1/5/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import SwiftUI

struct FontColorKey: EnvironmentKey {
    static var defaultValue: UIColor {
        #if os(iOS) || os(macOS)
        return UIColor { $0.userInterfaceStyle == .light ?  #colorLiteral(red: 0.2588235294, green: 0.2588235294, blue: 0.2588235294, alpha: 1) : #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1) }
        #else
        return #colorLiteral(red: 0.2588235294, green: 0.2588235294, blue: 0.2588235294, alpha: 1)
        #endif
    }
}

extension EnvironmentValues {
    var fontColor: UIColor {
        self[FontColorKey.self]
    }
}
