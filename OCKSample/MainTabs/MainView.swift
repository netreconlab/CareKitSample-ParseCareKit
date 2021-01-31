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

struct StoreManagerKey: EnvironmentKey {
    
    static var defaultValue: OCKSynchronizedStoreManager? {
        let extensionDelegate = UIApplication.shared.delegate as! AppDelegate
        return extensionDelegate.synchronizedStoreManager
    }
}

extension EnvironmentValues {
    
    var storeManager: OCKSynchronizedStoreManager? {
        get {
            self[StoreManagerKey.self]
        }
        
        set{
            self[StoreManagerKey.self] = newValue
        }
    }
}


struct MainView: View {
    
    @Environment(\.storeManager) private var storeManager
    @State private var selectedTab = 0
    @State private var tintColor = UIColor { $0.userInterfaceStyle == .light ?  #colorLiteral(red: 0, green: 0.2858072221, blue: 0.6897063851, alpha: 1) : #colorLiteral(red: 0.06253327429, green: 0.6597633362, blue: 0.8644603491, alpha: 1) }
    
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
                
            
            ContactView(manager: storeManager!)
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
        }
        .accentColor(Color(tintColor))
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
