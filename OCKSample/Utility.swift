//
//  Utility.swift
//  OCKSample
//
//  Created by Corey Baker on 10/16/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

import Foundation

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
}
