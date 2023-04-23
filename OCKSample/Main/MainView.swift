//
//  MainView.swift
//  OCKSample
//
//  Created by Corey Baker on 11/25/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.

import CareKit
import CareKitStore
import CareKitUI
import SwiftUI

struct MainView: View {
    @EnvironmentObject private var appDelegate: AppDelegate
    @StateObject private var loginViewModel = LoginViewModel()
    @State private var path = [MainViewPath]()
    @State private var storeCoordinator = OCKStoreCoordinator()

    var body: some View {
        NavigationStack(path: $path) {
            LoginView(viewModel: loginViewModel)
                .navigationDestination(for: MainViewPath.self) { destination in
                    switch destination {
                    case .tabs:
                        if isSyncingWithRemote {
                            MainTabView(loginViewModel: loginViewModel)
                                .navigationBarHidden(true)
                        } else {
                            CareView()
                                .navigationBarHidden(true)
                        }
                    }
                }
                .onAppear {
                    guard isSyncingWithRemote else {
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
            .environment(\.appDelegate, AppDelegate())
            .environment(\.careStore, Utility.createPreviewStore())
            .accentColor(Color(TintColorKey.defaultValue))
    }
}
