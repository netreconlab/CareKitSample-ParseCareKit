//
//  ParseObjects.swift
//  OCKSample
//
//  Created by Corey Baker on 9/28/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import Foundation
import ParseSwift

struct User: ParseUser {
    var username: String?
    
    var email: String?
    
    var password: String?
    
    var objectId: String?
    
    var createdAt: Date?
    
    var updatedAt: Date?
    
    var ACL: ParseACL? = try? ParseACL.defaultACL()
}
