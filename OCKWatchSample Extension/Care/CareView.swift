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

    @Environment(\.tintColor) private var tintColor
    @Environment(\.customStyle) private var style
    @Environment(\.storeManager) private var storeManager
    @StateObject var loginViewModel = LoginViewModel()
    @StateObject var viewModel = CareViewModel()
    @StateObject var userStatus = UserStatus()

    var body: some View {

        ScrollView {

            if !userStatus.isLoggedOut || !loginViewModel.syncWithCloud {
                let storeManager = viewModel.storeManager

                InstructionsTaskView(taskID: TaskID.stretch,
                                     eventQuery: OCKEventQuery(for: Date()),
                                     storeManager: storeManager)

            } else {
                Text("Please open the OCKSample app on your iPhone and login")
                    .multilineTextAlignment(.center)
                    .padding()
                Image(systemName: "apps.iphone")
                    .resizable()
                    .frame(width: 50, height: 50.0)
            }

        }
        .accentColor(Color(tintColor))
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
    /*
    init() {
        self._loginViewModel = StateObject(wrappedValue: LoginViewModel())
        self._viewModel = StateObject(wrappedValue: CareViewModel())
        self._userStatus = StateObject(wrappedValue: UserStatus())
    }*/
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        CareView()
    }
}
