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

    static var defaultValue: Style {
        Style()
    }
}

extension EnvironmentValues {

    var customStyle: Style {
        self[CustomStyleKey.self]
    }
}
