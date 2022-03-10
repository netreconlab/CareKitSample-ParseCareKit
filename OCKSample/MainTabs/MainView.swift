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
    @Environment(\.userProfileViewModel) private var profileViewModel
    @StateObject var userStatus = UserStatus()
    @State private var selectedTab = 0

    var body: some View {

        NavigationView {
            VStack {
                NavigationLink(destination: LoginView(),
                               isActive: $userStatus.isLoggedOut) {
                   EmptyView()
                }
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
                        .navigationBarTitle("")
                        .navigationBarHidden(true)

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
                        .navigationBarTitle("")
                        .navigationBarHidden(true)

                    ProfileView()
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
                        .navigationBarTitle("")
                        .navigationBarHidden(true)
                }
            }
        }
        .environmentObject(userStatus)
        .statusBar(hidden: true)
        .accentColor(Color(tintColor))
        .careKitStyle(Style())
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
