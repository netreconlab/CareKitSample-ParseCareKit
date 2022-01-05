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

    @Environment(\.storeManager) private var storeManager
    @StateObject var login = LoginViewModel()
    @StateObject var viewModel = CareViewModel()
    // swiftlint:disable:next force_cast
    let watchDelegate = WKExtension.shared().delegate as! ExtensionDelegate

    var body: some View {

        ScrollView {

            if User.current != nil || !login.syncWithCloud {

                if viewModel.isOnboarded {
                    InstructionsTaskView(taskID: TaskID.stretch,
                                         eventQuery: OCKEventQuery(for: Date()),
                                         storeManager: watchDelegate.storeManager)
                } else {
                    Text("Please open the OCKSample app on your iPhone and complete onboarding")
                        .multilineTextAlignment(.center)
                        .padding()
                    Image(systemName: "doc.text")
                        .resizable()
                        .frame(width: 50, height: 50.0)
                }

            } else {
                Text("Please open the OCKSample app on your iPhone and login")
                    .multilineTextAlignment(.center)
                    .padding()
                Image(systemName: "apps.iphone")
                    .resizable()
                    .frame(width: 50, height: 50.0)
            }

        }
        .onAppear(perform: {
            guard watchDelegate.store != nil else {
                return
            }
            watchDelegate.store.synchronize { error in
                let errorString = error?.localizedDescription ?? "Successful sync with iPhone!"
                Logger.feed.info("\(errorString)")
                if !self.viewModel.isOnboarded {
                    Task {
                        await self.viewModel.checkIfOnboardingIsComplete()
                    }
                }
            }
        })
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        CareView()
    }
}
