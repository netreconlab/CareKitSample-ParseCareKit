//
//  CareView.swift
//  OCKWatchSample Extension
//
//  Created by Corey Baker on 6/25/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
//

import CareKit
import CareKitEssentials
import CareKitStore
import CareKitUI
import SwiftUI
import os.log

struct CareView: View {

    @CareStoreFetchRequest(query: query()) private var events
    @State var sortedTaskIDs: [String: Int] = [:]

    private var orderedEvents: [CareStoreFetchedResult<OCKAnyEvent>] {
        events.latest.sorted(by: { left, right in
            let leftTaskID = left.result.task.id
            let rightTaskID = right.result.task.id

            return sortedTaskIDs[leftTaskID] ?? 0 < sortedTaskIDs[rightTaskID] ?? 0
        })
    }

    var body: some View {
        ScrollView {
            ForEach(orderedEvents) { event in
                if event.result.task.id == TaskID.kegels {
                    SimpleTaskView(event: event)
                } else {
                    InstructionsTaskView(event: event)
                }
            }
        }.onAppear {
            let taskIDs = TaskID.orderedWatchOS
            sortedTaskIDs = computeTaskIDOrder(taskIDs: taskIDs)
            events.query.taskIDs = taskIDs
        }
    }

    static func query() -> OCKEventQuery {
        var query = OCKEventQuery(for: Date())
        query.taskIDs = TaskID.orderedWatchOS
        return query
    }

    private func computeTaskIDOrder(taskIDs: [String]) -> [String: Int] {
        // Tie index values to TaskIDs.
        let sortedTaskIDs = taskIDs.enumerated().reduce(into: [String: Int]()) { taskDictionary, task in
            taskDictionary[task.element] = task.offset
        }

        return sortedTaskIDs
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        CareView()
            .environment(\.careStore, Utility.createPreviewStore())
			.careKitStyle(Styler())
    }
}
