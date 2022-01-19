//
//  OCKPatient+Parse.swift
//  OCKSample
//
//  Created by Corey Baker on 1/5/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import CareKitStore
import ParseSwift

extension OCKPatient {
    /**
    The Remote Clock UUID for this Patient.
    */
    var remoteClockUUID: UUID? {
        get {
            guard let uuidString = remoteID,
                let uuid = UUID(uuidString: uuidString) else {
                return nil
            }
            return uuid
        }
        set {
            remoteID = newValue?.uuidString
        }
    }

    /**
    The user type of this Patient.
    */
    var userType: UserType? {
        get {
            guard let typeString = userInfo?[Constants.userTypeKey],
                let type = UserType(rawValue: typeString) else {
                return nil
            }
            return type
        }
        set {
            guard let type = newValue else {
                userInfo?.removeValue(forKey: Constants.userTypeKey)
                return
            }
            if userInfo != nil {
                userInfo?[Constants.userTypeKey] = type.rawValue
            } else {
                userInfo = [Constants.userTypeKey: type.rawValue]
            }
        }
    }

    /// Initialize a patient with an id, a first name, and a last name.
    ///
    /// - Parameters:
    ///   - remoteUUID: An identifier for this patient in a remote store.
    ///   - id: A user-defined id unique to this patient.
    ///   - givenName: The patient's given name.
    ///   - familyName: The patient's family name.
    init(remoteUUID: UUID, id: String, givenName: String, familyName: String) {
        self.init(id: id,
                  givenName: givenName,
                  familyName: familyName)
        remoteClockUUID = remoteUUID
    }
}
