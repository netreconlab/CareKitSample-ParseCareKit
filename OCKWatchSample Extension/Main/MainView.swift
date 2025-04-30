//
//  MainView.swift
//  OCKSample
//
//  Created by Corey Baker on 9/23/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import CareKitEssentials
import CareKitStore
import CareKitUI
import SwiftUI
import os.log

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
						MainTabView(loginViewModel: loginViewModel)
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
		.environment(\.careStore, storeCoordinator)
		.onReceive(appDelegate.$storeCoordinator) { newStoreCoordinator in
			Task {
				await loginViewModel.checkStatus()
			}
			guard newStoreCoordinator !== storeCoordinator else {
				return
			}
			storeCoordinator = newStoreCoordinator
			updatePath([.tabs])
		}
        .onReceive(loginViewModel.$isLoggedOut) { isLoggedOut in
            guard isSyncingWithRemote else {
                updatePath([.tabs])
                return
            }
            guard !isLoggedOut else {
                updatePath([])
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
			.environment(\.appDelegate, AppDelegate())
			.environment(\.careStore, Utility.createPreviewStore())
			.careKitStyle(Styler())
    }
}
