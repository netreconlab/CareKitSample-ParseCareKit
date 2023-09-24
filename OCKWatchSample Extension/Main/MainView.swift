//
//  MainView.swift
//  OCKSample
//
//  Created by Corey Baker on 9/23/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import SwiftUI
import CareKitStore
import os.log

struct MainView: View {
    @EnvironmentObject private var appDelegate: AppDelegate
    @StateObject private var loginViewModel = LoginViewModel()
    @State private var path = [MainViewPath]()
    @State private var store = OCKStore(name: Constants.noCareStoreName,
                                        type: .inMemory)

    var body: some View {
        NavigationStack(path: $path) {
            LoginView(viewModel: loginViewModel)
                .navigationDestination(for: MainViewPath.self) { destination in
                    switch destination {
                    case .tabs:
                        CareView()
                            .navigationBarHidden(true)
                    }
                }
                .navigationBarHidden(true)
                .onAppear {
                    guard isSyncingWithRemote else {
                        updatePath([.tabs])
                        return
                    }
                    guard !loginViewModel.isLoggedOut else {
                        updatePath([])
                        return
                    }
                    updatePath([.tabs])
                }
        }
        .environment(\.careStore, store)
        .onReceive(loginViewModel.$isLoggedOut, perform: { isLoggedOut in
            guard isSyncingWithRemote else {
                updatePath([.tabs])
                return
            }
            guard !isLoggedOut else {
                updatePath([])
                return
            }
            updatePath([.tabs])
        })
        .onReceive(appDelegate.$store) { newStore in
            Task {
                await loginViewModel.checkStatus()
            }
            guard let newStore = newStore,
                  store.name != newStore.name else {
                return
            }
            store = newStore
            guard isSyncingWithRemote else {
                updatePath([.tabs])
                return
            }
            updatePath([.tabs])
        }
    }

    @MainActor
    func updatePath(_ path: [MainViewPath]) {
        self.path = path
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
            .accentColor(Color(TintColorKey.defaultValue))
    }
}
