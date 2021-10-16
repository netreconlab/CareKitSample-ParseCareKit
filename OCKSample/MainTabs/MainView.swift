//
//  MainView.swift
//  OCKSample
//
//  Created by Corey Baker on 11/25/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
// This was built using tutorial: https://www.hackingwithswift.com/books/ios-swiftui/creating-tabs-with-tabview-and-tabitem

import SwiftUI
import CareKit
import CareKitStore
import CareKitUI
import UIKit

//This file is the SwiftUI equivalent to UITabBarController in setupTabBarController() in SceneDelegate.swift

struct MainView: View {
    
    @Environment(\.storeManager) private var storeManager
    @Environment(\.tintColor) private var tintColor
    @State private var selectedTab = 0
    @ObservedObject var profile = ProfileViewModel()
    
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

            ContactView(manager: storeManager)
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
            
            ProfileView(profileViewModel: profile)
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
        .accentColor(Color(tintColor))
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
