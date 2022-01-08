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
        UIColor { $0.userInterfaceStyle == .light ?  #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1) : #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1) }
    }
}

extension EnvironmentValues {

    var fontColor: UIColor {
        self[FontColorKey.self]
    }
}
