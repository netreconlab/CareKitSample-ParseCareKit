//
//  OCKSampleApp.swift
//  OCKSample
//
//  Created by Corey Baker on 9/2/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import SwiftUI
import CareKit

@main
struct OCKSampleApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @Environment(\.tintColor) private var tintColor
    @Environment(\.careKitStyle) private var style

    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(\.appDelegate, appDelegate)
                .accentColor(Color(tintColor))
                .careKitStyle(Styler())
        }
    }
}
