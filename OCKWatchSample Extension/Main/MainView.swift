//
//  MainView.swift
//  OCKSample
//
//  Created by Corey Baker on 9/23/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import SwiftUI

struct MainView: View {
    @StateObject var loginViewModel = LoginViewModel()
    @StateObject var careViewModel = CareViewModel()

    var body: some View {
        ScrollView {
            if isSyncingWithCloud {
                if !loginViewModel.isLoggedOut {
                    CareView(viewModel: careViewModel)
                } else {
                    LoginView(viewModel: loginViewModel)
                }
            } else {
                CareView(viewModel: careViewModel)
            }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
