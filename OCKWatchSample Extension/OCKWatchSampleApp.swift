//
//  OCKWatchSampleApp.swift
//  OCKWatchSample Extension
//
//  Created by Corey Baker on 6/25/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
//

import WatchKit
import SwiftUI

@main
struct OCKWatchSampleApp: App {
    @WKApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @Environment(\.customStyler) private var style
    @SceneBuilder var body: some Scene {
        WindowGroup {
            MainView()
            .environment(\.appDelegate, appDelegate)
            .careKitStyle(style)
        }
        WKNotificationScene(controller: NotificationController.self, category: "myCategory")
    }
}
