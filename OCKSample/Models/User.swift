//
//  User.swift
//  OCKSample
//
//  Created by Corey Baker on 9/28/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import ParseSwift

struct User: ParseUser {
    // Required properties
    var authData: [String: [String: String]?]?
    var username: String?
    var email: String?
    var emailVerified: Bool?
    var password: String?
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?

    // Custom properties
    var lastTypeSelected: String?
    var userTypeUUIDs: [String: UUID]?
}

// MARK: Default Implementation
extension User {
    func merge(with object: Self) throws -> Self {
        var updated = try mergeParse(with: object)
        if updated.shouldRestoreKey(\.lastTypeSelected,
                                     original: object) {
            updated.lastTypeSelected = object.lastTypeSelected
        }
        if updated.shouldRestoreKey(\.userTypeUUIDs,
                                     original: object) {
            updated.userTypeUUIDs = object.userTypeUUIDs
        }
        return updated
    }
}
