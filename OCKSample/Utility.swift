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
    // For classes, we can use "class" or "static" to declare type methods/properties.
    class func prepareSyncMessageForWatch() -> [String: Any] {
        var returnMessage = [String: Any]()
        returnMessage[Constants.requestSync] = "new messages in Cloud"
        return returnMessage
    }

    class func getUserSessionForWatch() -> [String: Any] {
        var returnMessage = [String: Any]()
        returnMessage[Constants.parseUserSessionTokenKey] = User.current?.sessionToken
        return returnMessage
    }

    class func getRemoteClockUUID() throws -> UUID {
        guard let lastUserTypeSelected = User.current?.lastTypeSelected,
              let remoteClockUUID = User.current?.userTypeUUIDs?[lastUserTypeSelected] else {
                  throw AppError.remoteClockIDNotAvailable
              }
        return remoteClockUUID
    }

    class func setDefaultACL() throws {
        var defaultACL = ParseACL()
        defaultACL.publicRead = false
        defaultACL.publicWrite = false
        _ = try ParseACL.setDefaultACL(defaultACL, withAccessForCurrentUser: true)
    }

    @MainActor
    class func setupRemoteAfterLogin() throws {
        let remoteUUID = try Utility.getRemoteClockUUID()
        do {
            try setDefaultACL()
        } catch {
            Logger.login.error("Could not set defaultACL: \(error.localizedDescription)")
        }

        guard let appDelegate = AppDelegateKey.defaultValue else {
            return
        }
        appDelegate.setupRemotes(uuid: remoteUUID)
        appDelegate.parseRemote.automaticallySynchronizes = true

        NotificationCenter.default.post(.init(name: Notification.Name(rawValue: Constants.requestSync)))
        return
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

    #if os(iOS)
    class func requestHealthKitPermissions() {
        AppDelegateKey.defaultValue?.healthKitStore.requestHealthKitPermissionsForAllTasksInStore { error in
            guard let error = error else {
                DispatchQueue.main.async {
                    // swiftlint:disable:next line_length
                    NotificationCenter.default.post(.init(name: Notification.Name(rawValue: Constants.finishedAskingForPermission)))
                }
                return
            }
            Logger.login.error("Error requesting HealthKit permissions: \(error.localizedDescription)")
        }
    }
    #endif
}
