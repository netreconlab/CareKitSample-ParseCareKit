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
    // @WKApplicationDelegateAdaptor private var delegate: ApplicationDelegate
    @WKExtensionDelegateAdaptor private var delegate: ApplicationDelegate
    @Environment(\.scenePhase) private var scenePhase
    @State var isActive = false
    @SceneBuilder var body: some Scene {
        WindowGroup {
            NavigationView {
                CareView()
                    .environment(\.appDelegate, delegate)
            }
        }
        WKNotificationScene(controller: NotificationController.self, category: "myCategory")
    }
}
