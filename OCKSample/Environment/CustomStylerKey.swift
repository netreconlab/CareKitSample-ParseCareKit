//
//  CustomStylerKey.swift
//  OCKSample
//
//  Created by Corey Baker on 2/26/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import SwiftUI

struct CustomStylerKey: EnvironmentKey {
    static var defaultValue: Styler {
        Styler()
    }
}

extension EnvironmentValues {

    var customStyler: Styler {
        self[CustomStylerKey.self]
    }
}
