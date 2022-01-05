//
//  Constants.swift
//  OCKSample
//
//  Created by Corey Baker on 11/27/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
//

import Foundation

enum AppError: Error {
    case couldntCast
    case valueNotFoundInUserInfo
}

extension AppError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .couldntCast:
            return NSLocalizedString("OCKSampleError: Couldn't cast to required type.",
                                     comment: "Casting error")
        case .valueNotFoundInUserInfo:
            return NSLocalizedString("OCKSampleError: Couldn't find the required value in userInfo.",
                                     comment: "Value not found error")
        }
    }
}

enum Constants {
    static let parseUserSessionTokenKey = "requestParseSessionToken"
    static let parseRemoteClockIDKey = "requestRemoteClockID"
    static let requestSync = "requestSync"
    static let progressUpdate = "progressUpdate"
    static let userLoggedIn = "userLoggedIn"
    static let storeIsInitialized = "storeIsInitialized"
}

enum TaskID {
    static let doxylamine = "doxylamine"
    static let nausea = "nausea"
    static let stretch = "stretch"
    static let kegels = "kegels"
    static let steps = "steps"

    static var ordered: [String] {
        [Self.steps, Self.doxylamine, Self.kegels, Self.stretch, Self.nausea]
    }

}
