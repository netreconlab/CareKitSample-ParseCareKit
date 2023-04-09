//
//  CareView.swift
//  OCKWatchSample Extension
//
//  Created by Corey Baker on 6/25/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
//

import CareKit
import CareKitStore
import CareKitUI
import SwiftUI
import os.log

struct CareView: View {
    @EnvironmentObject private var appDelegate: AppDelegate
    @CareStoreFetchRequest(query: OCKEventQuery(for: Date())) private var events
    @StateObject var viewModel = CareViewModel()

    var body: some View {
        ScrollView {
            ForEach(events) { event in
                if event.result.task.id == TaskID.kegels {
                    SimpleTaskView(event: event)
                } else if event.result.task.id == TaskID.stretch {
                    InstructionsTaskView(event: event)
                } else {
                    SimpleTaskView(event: event)
                }
            }
        }.onReceive(appDelegate.$store) { newStore in
            viewModel.synchronizeStore(newStore)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        CareView()
            .accentColor(Color(TintColorKey.defaultValue))
    }
}
