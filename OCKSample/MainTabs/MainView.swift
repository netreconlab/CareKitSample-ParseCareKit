//
//  MainView.swift
//  OCKSample
//
//  Created by Corey Baker on 11/25/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
// swiftlint:disable:next line_length
// This was built using tutorial: https://www.hackingwithswift.com/books/ios-swiftui/creating-tabs-with-tabview-and-tabitem

import SwiftUI
import CareKit
import CareKitStore
import CareKitUI
import UIKit

// This file is the SwiftUI equivalent to UITabBarController in setupTabBarController() in SceneDelegate.swift

struct MainView: View {

    @Environment(\.presentationMode) var presentationMode
    @Environment(\.storeManager) private var storeManager
    @Environment(\.tintColor) private var tintColor
    @Environment(\.careKitStyle) private var style
    @StateObject private var loginViewModel = LoginViewModel()
    @StateObject private var profileViewModel = ProfileViewModel()
    @StateObject private var userStatus = UserStatus()
    @State private var path = [MainViewPath]()

    var body: some View {
        NavigationStack(path: $path) {
            EmptyView()
            .navigationDestination(for: MainViewPath.self) { destination in
                switch destination {
                case .login:
                    LoginView(viewModel: loginViewModel)
                case .tab:
                    MainTabView(loginViewModel: loginViewModel,
                                profileViewModel: profileViewModel)
                }
            }
            .onAppear {
                path.append(.login)
                if !userStatus.isLoggedOut {
                    path.append(.tab)
                } else if userStatus.isLoggedOut {
                    path = [.login]
                }
            }
        }
        .statusBar(hidden: true)
        .accentColor(Color(tintColor))
        .careKitStyle(Style())
        .onReceive(loginViewModel.$isLoggedOut, perform: { isLoggedOut in
            if !isLoggedOut {
                path.append(.tab)
            } else {
                path = [.login]
            }
        })
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
