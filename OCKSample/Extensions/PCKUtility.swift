//
//  PCKUtility.swift
//  OCKSample
//
//  Created by Corey Baker on 1/22/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import ParseCareKit
import ParseSwift

extension PCKUtility {

    /**
     Check server health.
     - returns: **true** if the server is available. **false** if the server reponds with not healthy.
     - throws: `ParseError`.
     */
    static func isServerAvailable() async throws -> Bool {
        let serverHealth = try await ParseHealth.check()
        guard serverHealth.contains("ok") else {
            return false
        }
        return true
    }
}
