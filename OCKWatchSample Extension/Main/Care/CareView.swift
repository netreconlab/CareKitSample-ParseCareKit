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
    @StateObject var viewModel = CareViewModel()

    var body: some View {
        ScrollView {
            SimpleTaskView(taskID: TaskID.kegels,
                           eventQuery: .init(for: Date()),
                           storeManager: viewModel.storeManager)
            InstructionsTaskView(taskID: TaskID.stretch,
                                 eventQuery: .init(for: Date()),
                                 storeManager: viewModel.storeManager)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        CareView(viewModel: .init(storeManager: Utility.createPreviewStoreManager()))
            .accentColor(Color(TintColorKey.defaultValue))
    }
}
