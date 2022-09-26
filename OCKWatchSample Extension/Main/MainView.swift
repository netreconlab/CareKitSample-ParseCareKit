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

    var body: some View {
        ScrollView {
            if isSyncingWithCloud {
                if !loginViewModel.isLoggedOut {
                    CareView()
                } else {
                    LoginView(viewModel: loginViewModel)
                }
            } else {
                CareView()
            }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
