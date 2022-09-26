//
//  MainTabView.swift
//  OCKSample
//
//  Created by Corey Baker on 9/18/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//
// swiftlint:disable:next line_length
// This was built using tutorial: https://www.hackingwithswift.com/books/ios-swiftui/creating-tabs-with-tabview-and-tabitem

import SwiftUI

struct MainTabView: View {
    @ObservedObject var loginViewModel: LoginViewModel
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            CareView()
                .tabItem {
                    if selectedTab == 0 {
                        Image("carecard-filled")
                            .renderingMode(.template)
                    } else {
                        Image("carecard")
                            .renderingMode(.template)
                    }
                }
                .tag(0)

            ContactView()
                .tabItem {
                    if selectedTab == 1 {
                        Image("phone.bubble.left.fill")
                            .renderingMode(.template)
                    } else {
                        Image("phone.bubble.left")
                            .renderingMode(.template)
                    }
                }
                .tag(1)

            ProfileView(loginViewModel: loginViewModel)
                .tabItem {
                    if selectedTab == 2 {
                        Image("connect-filled")
                            .renderingMode(.template)
                    } else {
                        Image("connect")
                            .renderingMode(.template)
                    }
                }
                .tag(2)
        }
        .navigationBarHidden(true)
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView(loginViewModel: .init())
            .accentColor(Color(TintColorKey.defaultValue))
    }
}
