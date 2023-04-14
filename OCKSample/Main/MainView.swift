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
    @EnvironmentObject private var appDelegate: AppDelegate
    @StateObject var loginViewModel = LoginViewModel()
    @State var path = [MainViewPath]()
    @State private var storeCoordinator = OCKStoreCoordinator()

    var body: some View {
        NavigationStack(path: $path) {
            LoginView(viewModel: loginViewModel)
                .navigationDestination(for: MainViewPath.self) { destination in
                    switch destination {
                    case .tabs:
                        if isSyncingWithCloud {
                            MainTabView(loginViewModel: loginViewModel)
                        } else {
                            CareView()
                                .navigationBarHidden(true)
                        }
                    }
                }
                .navigationBarHidden(true)
                .onAppear {
                    guard isSyncingWithCloud else {
                        path = [.tabs]
                        return
                    }
                    guard !loginViewModel.isLoggedOut else {
                        path = []
                        return
                    }
                    path = [.tabs]
                }
        }
        .environment(\.careStore, storeCoordinator)
        .onReceive(loginViewModel.$isLoggedOut, perform: { isLoggedOut in
            guard !isLoggedOut else {
                path = []
                return
            }
            path = [.tabs]
        })
        .onReceive(appDelegate.$storeCoordinator) { newStoreCoordinator in
            guard storeCoordinator !== newStoreCoordinator else {
                return
            }
            storeCoordinator = newStoreCoordinator
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
            .environment(\.careStore, Utility.createPreviewStore())
            .accentColor(Color(TintColorKey.defaultValue))
    }
}
