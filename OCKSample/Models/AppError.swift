//
//  AppError.swift
//  OCKSample
//
//  Created by Corey Baker on 4/14/23.
//  Copyright © 2023 Network Reconnaissance Lab. All rights reserved.
//

import CareKitStore
import Foundation
import ParseSwift

enum AppError: Error {
    case couldntCast
    case couldntBeUnwrapped
    case valueNotFoundInUserInfo
    case remoteClockIDNotAvailable
    case emptyTaskEvents
    case invalidIndexPath(_ indexPath: IndexPath)
    case noOutcomeValueForEvent(_ event: OCKAnyEvent, index: Int)
    case cannotMakeOutcomeFor(_ event: OCKAnyEvent)
    case parseError(_ error: ParseError)
    case error(_ error: Error)
    case errorString(_ string: String)
}

extension AppError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .couldntCast:
            return NSLocalizedString("OCKSampleError: Could not cast to required type.",
                                     comment: "Casting error")
        case .couldntBeUnwrapped:
            return NSLocalizedString("OCKSampleError: Could not unwrap a required type.",
                                     comment: "Unwrapping error")
        case .valueNotFoundInUserInfo:
            return NSLocalizedString("OCKSampleError: Could not find the required value in userInfo.",
                                     comment: "Value not found error")
        case .remoteClockIDNotAvailable:
            return NSLocalizedString("OCKSampleError: Could not get remote clock ID.",
                                     comment: "Value not available error")
        case .emptyTaskEvents: return "Task events is empty"
        case let .noOutcomeValueForEvent(event, index): return "Event has no outcome value at index \(index): \(event)"
        case .invalidIndexPath(let indexPath): return "Invalid index path \(indexPath)"
        case .cannotMakeOutcomeFor(let event): return "Cannot make outcome for event: \(event)"
        case .parseError(let error): return "\(error)"
        case .error(let error): return "\(error)"
        case .errorString(let string): return string
        }
    }
}
