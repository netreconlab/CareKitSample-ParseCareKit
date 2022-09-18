//
//  MainTabView.swift
//  OCKSample
//
//  Created by Corey Baker on 9/18/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var userStatus: UserStatus
    @ObservedObject var loginViewModel: LoginViewModel
    @ObservedObject var profileViewModel: ProfileViewModel
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

            ProfileView(viewModel: profileViewModel, loginViewModel: loginViewModel)
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
        .onReceive(loginViewModel.$isLoggedOut, perform: { value in
            if self.userStatus.isLoggedOut != value {
                self.userStatus.check()
            }
        })
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView(loginViewModel: .init(), profileViewModel: .init())
            .environmentObject(UserStatus(isLoggedOut: false))
    }
}
