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
    @WKApplicationDelegateAdaptor private var delegate: AppDelegate
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.tintColor) private var tintColor
    @Environment(\.customStyler) private var style
    @State var isActive = false
    @SceneBuilder var body: some Scene {
        WindowGroup {
            MainView()
            .environment(\.appDelegate, delegate)
            .accentColor(Color(tintColor))
            .careKitStyle(style)
        }
        WKNotificationScene(controller: NotificationController.self, category: "myCategory")
    }
}
