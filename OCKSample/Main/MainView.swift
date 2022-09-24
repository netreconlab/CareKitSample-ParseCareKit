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
import UIKit

struct MainView: View {
    @Environment(\.tintColor) private var tintColor
    @Environment(\.careKitStyle) private var style
    @StateObject private var loginViewModel = LoginViewModel()
    @StateObject private var profileViewModel = ProfileViewModel()
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
                        MainTabView(loginViewModel: loginViewModel,
                                    profileViewModel: profileViewModel)
                    } else {
                        CareView()
                    }
                }
            }
            .onAppear {
                guard isSyncingWithCloud else {
                    setTabAsOnlyPath()
                    return
                }
                setLoginAsOnlyPath()
                if !loginViewModel.isLoggedOut {
                    appendPath(.tab)
                }
            }
        }
        .statusBar(hidden: true)
        .accentColor(Color(tintColor))
        .careKitStyle(Styler())
        .onReceive(loginViewModel.$isLoggedOut, perform: { isLoggedOut in
            setLoginAsOnlyPath()
            if !isLoggedOut {
                appendPath(.tab)
            }
        })
    }

    // MARK: Helpers
    func setLoginAsOnlyPath() {
        if path.first != .login || path.count > 1 {
            path = [.login]
        }
    }

    func setTabAsOnlyPath() {
        if path.first != .tab || path.count > 1 {
            path = [.tab]
        }
    }

    func appendPath(_ path: MainViewPath) {
        guard self.path.last != path else {
            return
        }
        self.path.append(path)
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
