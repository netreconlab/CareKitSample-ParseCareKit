//
//  UserStatus.swift
//  OCKSample
//
//  Created by Corey Baker on 1/7/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import Foundation

@MainActor
class UserStatus: ObservableObject {
    @Published var isLoggedOut = true

    init() {
        check()
    }

    func check() {
        if User.current != nil {
            isLoggedOut = false
        } else {
            isLoggedOut = true
        }
    }
}
