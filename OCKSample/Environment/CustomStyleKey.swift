//
//  CustomStyleKey.swift
//  OCKSample
//
//  Created by Corey Baker on 2/26/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import SwiftUI

struct CustomStyleKey: EnvironmentKey {

    static var defaultValue: Styler {
        Styler()
    }
}

extension EnvironmentValues {

    var customStyle: Styler {
        self[CustomStyleKey.self]
    }
}
