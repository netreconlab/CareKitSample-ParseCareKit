//
//  Logger.swift
//  OCKSample
//
//  Created by Corey Baker on 10/16/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import os.log

extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier!
    static let store = Logger(subsystem: subsystem, category: "Store")
    static let appDelegate = Logger(subsystem: subsystem, category: "AppDelegate")
    static let extensionDelegate = Logger(subsystem: subsystem, category: "ExtensionDelegate")
    static let contact = Logger(subsystem: subsystem, category: "Contact")
    static let login = Logger(subsystem: subsystem, category: "Login")
    static let feed = Logger(subsystem: subsystem, category: "Feed")
    static let watch = Logger(subsystem: subsystem, category: "Watch")
    static let profile = Logger(subsystem: subsystem, category: "Profile")
    static let insights = Logger(subsystem: subsystem, category: "Insights")
    static let sceneDelegate = Logger(subsystem: subsystem, category: "SceneDelegate")
    static let ockStore = Logger(subsystem: subsystem, category: "OCKStore+Extension")
    static let ockHealthKitPassthroughStore = Logger(subsystem: subsystem,
                                                     category: "OCKHealthKitPassthroughStore+Extension")
}
