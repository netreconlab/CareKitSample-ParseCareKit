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

    @Environment(\.customStyler) private var style
    @ObservedObject var viewModel: CareViewModel

    var body: some View {
        InstructionsTaskView(taskID: TaskID.stretch,
                             eventQuery: OCKEventQuery(for: Date()),
                             storeManager: viewModel.storeManager)
        .onAppear(perform: {
            viewModel.synchronizeStore()
        })
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        CareView(viewModel: .init())
    }
}
