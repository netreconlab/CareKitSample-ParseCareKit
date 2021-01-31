//
//  ParseObjects.swift
//  OCKSample
//
//  Created by Corey Baker on 9/28/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import ParseSwift

struct User: ParseUser {
    var authData: [String : [String : String]?]?
    
    var username: String?
    
    var email: String?
    
    var password: String?
    
    var objectId: String?
    
    var createdAt: Date?
    
    var updatedAt: Date?
    
    var ACL: ParseACL?
    
    init() {
        ACL = try? ParseACL.defaultACL()
    }
}

struct Installation: ParseInstallation {
    var deviceType: String?
    
    var installationId: String?
    
    var deviceToken: String?
    
    var badge: Int?
    
    var timeZone: String?
    
    var channels: [String]?
    
    var appName: String?
    
    var appIdentifier: String?
    
    var appVersion: String?
    
    var parseVersion: String?
    
    var localeIdentifier: String?
    
    var objectId: String?
    
    var createdAt: Date?
    
    var updatedAt: Date?
    
    var ACL: ParseACL?
    
    init() {
        ACL = try? ParseACL.defaultACL()
    }
}
