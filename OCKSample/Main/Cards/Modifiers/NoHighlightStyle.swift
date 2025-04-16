//
//  NoHighlightStyle.swift
//  OCKSample
//
//  Created by Corey Baker on 3/27/25.
//  Copyright © 2025 Network Reconnaissance Lab. All rights reserved.
//

import SwiftUI

struct NoHighlightStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        return configuration.label.contentShape(Rectangle())
    }
}
