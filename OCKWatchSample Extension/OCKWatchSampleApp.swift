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
    // @WKExtensionDelegateAdaptor private var applicationDelegate: ExtensionDelegate
    @WKApplicationDelegateAdaptor private var delegate: ApplicationDelegate
    @Environment(\.scenePhase) private var scenePhase
    @State var isActive = false
    @SceneBuilder var body: some Scene {
        WindowGroup {
            NavigationView {
                CareView()
                    .environment(\.appDelegate, delegate)
            }
        }
        .onChange(of: scenePhase) { phase in
            switch phase {

            case .background:
                print("background")
            case .inactive:
                print("inactive")
            case .active:
                isActive.toggle()
                print(delegate)
            @unknown default:
                print("Reached an unknown phase")
            }
            if phase == .background {
                // Perform cleanup when all scenes within
                // MyApp go to the background.
            }
        }
        WKNotificationScene(controller: NotificationController.self, category: "myCategory")
    }
}
