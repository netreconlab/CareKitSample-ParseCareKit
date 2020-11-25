//
//  MainSwiftUIView.swift
//  OCKSample
//
//  Created by Corey Baker on 11/25/20.
//  Copyright © 2020 Apple. All rights reserved.
// This was built using tutorial: https://www.hackingwithswift.com/books/ios-swiftui/creating-tabs-with-tabview-and-tabitem

import SwiftUI
import CareKit
import CareKitStore
import CareKitUI

//This file is the SwiftUI equivalent to UITabBarController in setupTabBarController() in SceneDelegate.swift

struct MainSwiftUIView: View {
    
    @State private var selectedTab = 0
    @State private var tintColor = UIColor { $0.userInterfaceStyle == .light ?  #colorLiteral(red: 0, green: 0.2858072221, blue: 0.6897063851, alpha: 1) : #colorLiteral(red: 0.06253327429, green: 0.6597633362, blue: 0.8644603491, alpha: 1) }
    let synchronizationManager: OCKSynchronizedStoreManager
    
    var body: some View {
        
        TabView(selection: $selectedTab) {
            
            CareSwiftUIView()
                .onTapGesture {
                    selectedTab = 0
                }
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
            
            ContactSwiftUIView(manager: synchronizationManager)
                .onTapGesture {
                    selectedTab = 1
                }
                .tabItem {
                    if selectedTab == 1 {
                        Image("connect-filled")
                            .renderingMode(.template)
                    } else {
                        Image("connect")
                            .renderingMode(.template)
                    }
                }
                .tag(1)
            
            ProfileView()
                .onTapGesture {
                    selectedTab = 2
                }
                .tabItem {
                    if selectedTab == 2 {
                        Image("symptoms-filled")
                            .renderingMode(.template)
                    } else {
                        Image("symptoms")
                            .renderingMode(.template)
                    }
                }
                .tag(2)
        }
        .accentColor(Color(tintColor))
    }
}

struct MainSwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        MainSwiftUIView(synchronizationManager: OCKSynchronizedStoreManager(wrapping: OCKStore(name: "test")))
    }
}
