//
//  CareView.swift
//  OCKWatchSample Extension
//
//  Created by Corey Baker on 6/25/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
//

import CareKit
import CareKitStore
import SwiftUI
import os.log

struct CareView: View {

    @Environment(\.customStyle) private var style
    @StateObject var loginViewModel = LoginViewModel()
    @StateObject var viewModel = CareViewModel()
    @StateObject var userStatus = UserStatus()

    var body: some View {

        ScrollView {

            if !userStatus.isLoggedOut || !loginViewModel.syncWithCloud {

                InstructionsTaskView(taskID: TaskID.stretch,
                                     eventQuery: OCKEventQuery(for: Date()),
                                     storeManager: viewModel.storeManager)

            } else {
                Text("Please open the OCKSample app on your iPhone and login")
                    .multilineTextAlignment(.center)
                    .padding()
                Image(systemName: "apps.iphone")
                    .resizable()
                    .frame(width: 50, height: 50.0)
            }

        }
        .careKitStyle(style)
        .onAppear(perform: {
            viewModel.synchronizeStore()
        })
        .onReceive(loginViewModel.$isLoggedOut, perform: { value in
            if self.userStatus.isLoggedOut != value {
                self.userStatus.check()
            }
        })
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        CareView()
    }
}
