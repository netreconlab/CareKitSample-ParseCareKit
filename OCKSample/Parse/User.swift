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
    var authData: [String : [String : String]?]?
    
    var username: String?
    
    var email: String?

    var emailVerified: Bool?
    
    var password: String?
    
    var objectId: String?
    
    var createdAt: Date?
    
    var updatedAt: Date?
    
    var ACL: ParseACL?
    
    init() {
        ACL = try? ParseACL.defaultACL()
    }
}
