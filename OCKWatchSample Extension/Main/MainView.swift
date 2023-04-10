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
    @StateObject var loginViewModel = LoginViewModel()
    @State var path = [MainViewPath]()
    @State private var store = OCKStore(name: Constants.noCareStoreName,
                                        type: .inMemory)

    var body: some View {
        NavigationStack(path: $path) {
            LoginView(viewModel: loginViewModel)
                .navigationDestination(for: MainViewPath.self) { destination in
                    switch destination {
                    case .tabs:
                        CareView()
                            .environment(\.careStore, store)
                            .navigationBarHidden(true)
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
        .onReceive(loginViewModel.$isLoggedOut, perform: { isLoggedOut in
            guard isSyncingWithCloud else {
                path = [.tabs]
                return
            }
            guard !isLoggedOut else {
                path = []
                return
            }
            path = [.tabs]
        })
        .onReceive(appDelegate.$store) { newStore in
            Task {
                await loginViewModel.checkStatus()
            }
            guard let newStore = newStore else {
                return
            }
            store = newStore
            guard isSyncingWithCloud else {
                path = [.tabs]
                return
            }
            path = [.tabs]
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
            .accentColor(Color(TintColorKey.defaultValue))
    }
}
