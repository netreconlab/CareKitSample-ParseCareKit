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
    @Environment(\.storeManager) private var storeManager
    @StateObject var loginViewModel = LoginViewModel()
    @StateObject var viewModel = CareViewModel()
    @StateObject var userStatus = UserStatus()
    // swiftlint:disable:next force_cast
    let watchDelegate = WKExtension.shared().delegate as! ExtensionDelegate

    var body: some View {

        ScrollView {

            if !userStatus.isLoggedOut || !loginViewModel.syncWithCloud {

                InstructionsTaskView(taskID: TaskID.stretch,
                                     eventQuery: OCKEventQuery(for: Date()),
                                     storeManager: watchDelegate.storeManager)

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
        .careKitStyle(Styler())
        .onAppear(perform: {
            guard watchDelegate.store != nil else {
                return
            }
            watchDelegate.store.synchronize { error in
                let errorString = error?.localizedDescription ?? "Successful sync with iPhone!"
                Logger.feed.info("\(errorString)")
            }
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
