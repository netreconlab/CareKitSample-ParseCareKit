//
//  MainView.swift
//  OCKSample
//
//  Created by Corey Baker on 11/25/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.

import CareKit
import CareKitEssentials
import CareKitStore
import CareKitUI
import SwiftUI

struct MainView: View {
    @EnvironmentObject private var appDelegate: AppDelegate
    @StateObject private var loginViewModel = LoginViewModel()
    @State private var storeCoordinator = OCKStoreCoordinator()
	@State private var isLoggedIn: Bool?

    var body: some View {
		Group {
			if let isLoggedIn {
				if isLoggedIn {
					if isSyncingWithRemote {
						MainTabView(loginViewModel: loginViewModel)
							.navigationBarHidden(true)
					} else {
						CareView()
							.navigationBarHidden(true)
					}
				} else {
					LoginView(viewModel: loginViewModel)
				}
			} else {
				Text("Loading...")
			}
		}
		.task {
			await loginViewModel.checkStatus()
		}
        .environment(\.careStore, storeCoordinator)
		.onReceive(appDelegate.$storeCoordinator) { newStoreCoordinator in
			guard storeCoordinator !== newStoreCoordinator else { return }
			storeCoordinator = newStoreCoordinator
		}
		.onReceive(loginViewModel.isLoggedIn.publisher) { currentStatus in
			isLoggedIn = currentStatus
        }
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
