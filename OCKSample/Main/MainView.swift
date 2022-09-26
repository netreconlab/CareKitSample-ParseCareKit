//
//  MainView.swift
//  OCKSample
//
//  Created by Corey Baker on 11/25/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.

import SwiftUI
import CareKit
import CareKitStore
import CareKitUI

struct MainView: View {
    @StateObject private var loginViewModel = LoginViewModel()
    @State private var path = [MainViewPath]()

    var body: some View {
        NavigationStack(path: $path) {
            EmptyView()
            .navigationDestination(for: MainViewPath.self) { destination in
                switch destination {
                case .login:
                    LoginView(viewModel: loginViewModel)
                case .tab:
                    if isSyncingWithCloud {
                        MainTabView(loginViewModel: loginViewModel)
                    } else {
                        CareView()
                            .navigationBarTitle("")
                            .navigationBarHidden(true)
                    }
                }
            }
            .onAppear {
                guard isSyncingWithCloud else {
                    path = [.tab]
                    return
                }
                guard !loginViewModel.isLoggedOut else {
                    path = [.login]
                    return
                }
                path = [.login, .tab]
            }
        }
        .statusBar(hidden: true)
        .onReceive(loginViewModel.$isLoggedOut, perform: { isLoggedOut in
            guard !isLoggedOut else {
                path = [.login]
                return
            }
            path = [.login, .tab]
        })
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
