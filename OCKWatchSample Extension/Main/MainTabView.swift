//
//  MainTabView.swift
//  OCKSample
//
//  Created by Corey Baker on 4/15/25.
//  Copyright © 2025 Network Reconnaissance Lab. All rights reserved.
//

import CareKitUI
import SwiftUI

struct MainTabView: View {

	@ObservedObject var loginViewModel: LoginViewModel

	var body: some View {
		TabView {
			CareView()
				.tabItem {
					Text(careTabName)
				}
			InsightsView()
				.tabItem {
					Text(insightsTabName)
				}
			ProfileView()
				.tabItem {
					Text(profileTabName)
				}
		}
		.task {
			await loginViewModel.checkStatus()
		}
	}

	private var careTabName: LocalizedStringKey {
		"CARE"
	}
	private var insightsTabName: LocalizedStringKey {
		"INSIGHTS"
	}
	private var profileTabName: LocalizedStringKey {
		"PROFILE"
	}
}

struct MainTabView_Previews: PreviewProvider {
	static var previews: some View {
		MainTabView(loginViewModel: .init())
			.environment(\.careStore, Utility.createPreviewStore())
			.careKitStyle(Styler())
	}
}
