//
//  Utility.swift
//  OCKSample
//
//  Created by Corey Baker on 10/16/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import ParseSwift
import os.log

class Utility {
    class func getUserSessionForWatch() -> [String: Any] {
        var returnMessage = [String: Any]()

        // Prepare data for watchOS
        guard let sessionToken = User.current?.sessionToken else {
            returnMessage[Constants.parseUserSessionTokenKey] = "not loggin in"
            return returnMessage
        }

        returnMessage[Constants.parseUserSessionTokenKey] = sessionToken
        // swiftlint:disable:next line_length
        returnMessage[Constants.parseRemoteClockIDKey] = UserDefaults.standard.object(forKey: Constants.parseRemoteClockIDKey)
        return returnMessage
    }

    class func updateInstallationWithDeviceToken(_ deviceToken: Data? = nil) async {
        guard let keychainInstallation = Installation.current else {
            Logger.utility.debug("""
                Attempted to update installation,
                but no current installation is available
            """)
            return
        }
        var isUpdatingInstallationMutable = true
        var currentInstallation = Installation()
        if keychainInstallation.objectId != nil {
            currentInstallation = keychainInstallation.mergeable
            if let deviceToken = deviceToken {
                currentInstallation.setDeviceToken(deviceToken)
            }
        } else {
            currentInstallation = keychainInstallation
            currentInstallation.objectId = UUID().uuidString
            currentInstallation.user = User.current
            currentInstallation.channels = [InstallationChannel.global.rawValue]
            isUpdatingInstallationMutable = false
        }
        let installation = currentInstallation
        let isUpdatingInstallation = isUpdatingInstallationMutable
        Task {
            do {
                if isUpdatingInstallation {
                    let updatedInstallation = try await installation.save()
                    Logger.utility.info("""
                        Updated installation: \(updatedInstallation, privacy: .private)
                    """)
                } else {
                    let updatedInstallation = try await installation.create()
                    Logger.utility.info("""
                        Created installation: \(updatedInstallation, privacy: .private)
                    """)
                }
            } catch {
                Logger.utility.error("""
                    Could not update installation: \(error.localizedDescription)
                """)
            }
        }
    }
}
