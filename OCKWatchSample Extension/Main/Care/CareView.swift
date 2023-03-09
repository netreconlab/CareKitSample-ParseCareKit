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
    @EnvironmentObject private var appDelegate: AppDelegate
    @StateObject var viewModel = CareViewModel()

    var body: some View {
        ScrollView {
            SimpleTaskView(taskID: TaskID.kegels,
                           eventQuery: .init(for: Date()),
                           storeManager: appDelegate.storeManager)
            InstructionsTaskView(taskID: TaskID.stretch,
                                 eventQuery: .init(for: Date()),
                                 storeManager: appDelegate.storeManager)
        }.onReceive(appDelegate.$storeManager) { newStoreManager in
            viewModel.synchronizeStore(storeManager: newStoreManager)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        CareView()
            .accentColor(Color(TintColorKey.defaultValue))
    }
}
