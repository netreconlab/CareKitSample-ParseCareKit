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
    @State private var storeCoordinator = OCKStoreCoordinator()
	@State private var isLoggedIn: Bool?

    var body: some View {
        Group {
			if let isLoggedIn {
				if isLoggedIn {
					MainTabView(loginViewModel: loginViewModel)
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
			Task {
				await loginViewModel.checkStatus()
			}
			guard newStoreCoordinator !== storeCoordinator else {
				return
			}
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
