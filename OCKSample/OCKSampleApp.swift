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

/**
 Set to **true** to sync with ParseServer, *false** to sync with iOS/watchOS.
 */
let isSyncingWithCloud = true

/**
 Set to **true** to use WCSession to notify watchOS about updates, **false** to not notify.
 A change in watchOS 9 removes the ability to use Websockets on real Apple Watches,
 preventing auto updates from the Parse Server. See the link for
 details: https://developer.apple.com/forums/thread/715024
 */
let isSendingPushUpdatesToWatch = true

@main
struct OCKSampleApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.tintColor) var tintColor
    @Environment(\.careKitStyle) var style

    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(\.appDelegate, appDelegate)
                .accentColor(Color(tintColor))
                .careKitStyle(Styler())
        }
    }
}
