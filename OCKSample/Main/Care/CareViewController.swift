/*
 Copyright (c) 2019, Apple Inc. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 3. Neither the name of the copyright holder(s) nor the names of any contributors
 may be used to endorse or promote products derived from this software without
 specific prior written permission. No license is granted to the trademarks of
 the copyright holders even if such marks are included in this software.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import Foundation
import UIKit
import SwiftUI
import Combine
import CareKit
import CareKitStore
import CareKitUI
import os.log

class CareViewController: OCKDailyPageViewController {

    private var isSyncing = false
    private var isLoading = false

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh,
                                                            target: self,
                                                            action: #selector(synchronizeWithRemote))
        NotificationCenter.default.addObserver(self, selector: #selector(synchronizeWithRemote),
                                               name: Notification.Name(rawValue: Constants.requestSync),
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateSynchronizationProgress(_:)),
                                               name: Notification.Name(rawValue: Constants.progressUpdate),
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reloadView(_:)),
                                               name: Notification.Name(rawValue: Constants.finishedAskingForPermission),
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reloadView(_:)),
                                               name: Notification.Name(rawValue: Constants.shouldRefreshView),
                                               object: nil)
    }

    @objc private func updateSynchronizationProgress(_ notification: Notification) {
        guard let receivedInfo = notification.userInfo as? [String: Any],
            let progress = receivedInfo[Constants.progressUpdate] as? Int else {
            return
        }

        DispatchQueue.main.async {
            switch progress {
            case 0, 100:
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "\(progress)",
                                                                         style: .plain, target: self,
                                                                         action: #selector(self.synchronizeWithRemote))
                if progress == 100 {
                    // Give sometime for the user to see 100
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh,
                                                                                 target: self,
                                                                                 // swiftlint:disable:next line_length
                                                                                 action: #selector(self.synchronizeWithRemote))
                        // swiftlint:disable:next line_length
                        self.navigationItem.rightBarButtonItem?.tintColor = self.navigationItem.leftBarButtonItem?.tintColor
                    }
                }
            default:
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "\(progress)",
                                                                         style: .plain, target: self,
                                                                         action: #selector(self.synchronizeWithRemote))
                self.navigationItem.rightBarButtonItem?.tintColor = TintColorKey.defaultValue
            }
        }
    }

    @MainActor
    @objc private func synchronizeWithRemote() {
        guard !isSyncing else {
            return
        }
        isSyncing = true
        AppDelegateKey.defaultValue?.store.synchronize { error in
            let errorString = error?.localizedDescription ?? "Successful sync with remote!"
            Logger.feed.info("\(errorString)")
            DispatchQueue.main.async {
                if error != nil {
                    self.navigationItem.rightBarButtonItem?.tintColor = .red
                } else {
                    self.navigationItem.rightBarButtonItem?.tintColor = self.navigationItem.leftBarButtonItem?.tintColor
                }
                self.isSyncing = false
            }
        }
    }

    @objc private func reloadView(_ notification: Notification? = nil) {
        guard !isLoading else {
            return
        }
        DispatchQueue.main.async {
            self.isLoading = true
            self.reload()
        }
    }

    /*
     This will be called each time the selected date changes.
     Use this as an opportunity to rebuild the content shown to the user.
     */
    override func dailyPageViewController(_ dailyPageViewController: OCKDailyPageViewController,
                                          prepare listViewController: OCKListViewController, for date: Date) {
        let isCurrentDay = Calendar.current.isDate(date, inSameDayAs: Date())

        // Only show the tip view on the current date
        if isCurrentDay {
            if Calendar.current.isDate(date, inSameDayAs: Date()) {
                // Add a non-CareKit view into the list
                let tipTitle = "Benefits of exercising"
                let tipText = "Learn how activity can promote a healthy pregnancy."
                let tipView = TipView()
                tipView.headerView.titleLabel.text = tipTitle
                tipView.headerView.detailLabel.text = tipText
                tipView.imageView.image = UIImage(named: "exercise.jpg")
                tipView.customStyle = CustomStylerKey.defaultValue
                listViewController.appendView(tipView, animated: false)
            }
        }

        Task {
            let (tasks, _) = await self.fetchTasks(on: date)
            tasks.compactMap {
                let cards = self.taskViewController(for: $0,
                                                    on: date)
                cards?.forEach {
                    if let carekitView = $0.view as? OCKView {
                        carekitView.customStyle = CustomStylerKey.defaultValue
                    }
                    $0.view.isUserInteractionEnabled = isCurrentDay
                    $0.view.alpha = !isCurrentDay ? 0.4 : 1.0
                }
                return cards
            }.forEach { (cards: [UIViewController]) in
                cards.forEach {
                    listViewController.appendViewController($0, animated: false)
                }
            }
            self.isLoading = false
        }
    }

    private func taskViewController(for task: OCKAnyTask,
                                    on date: Date) -> [UIViewController]? {

        var query = OCKEventQuery(for: Date())
        query.taskIDs = [task.id]

        switch task.id {
        /* case TaskID.steps:
            let title = task.title
            let firstOutcome = event.outcome?.sortedOutcomeValuesByRecency().values.first
            let computedProgress = event.computeProgress()
            let progress = firstOutcome?.doubleValue ?? 0.0
            let goal: Double = progress / computedProgress.fractionCompleted
            let isCompleted = event.computeProgress().isCompleted
            let view = NumericProgressTaskView(title: Text(title ?? ""),
                                               progress: Text("\(progress)"),
                                               goal: Text("\(goal)"),
                                               isComplete: isCompleted)
                .padding([.vertical], 20)
                .careKitStyle(CustomStylerKey.defaultValue)

            return [view.formattedHostingController()] */
        case TaskID.stretch:
            return [OCKInstructionsTaskViewController(query: query,
                                                      store: self.store)]

        case TaskID.kegels:
            /*
             Since the kegel task is only scheduled every other day, there will be cases
             where it is not contained in the tasks array returned from the query.
             */
            return [OCKSimpleTaskViewController(query: query,
                                                store: self.store)]

        // Create a card for the doxylamine task if there are events for it on this day.
        case TaskID.doxylamine:

            return [OCKChecklistTaskViewController(query: query,
                                                   store: self.store)]

        case TaskID.nausea:
            var cards = [UIViewController]()
            // dynamic gradient colors
            let nauseaGradientStart = TintColorFlipKey.defaultValue
            let nauseaGradientEnd = TintColorKey.defaultValue

            // Create a plot comparing nausea to medication adherence.
            let nauseaDataSeries = OCKDataSeriesConfiguration(
                taskID: task.id,
                legendTitle: "Nausea",
                gradientStartColor: nauseaGradientStart,
                gradientEndColor: nauseaGradientEnd,
                markerSize: 10) { event in
                    event.computeProgress(by: .summingOutcomeValues)
                }

            let doxylamineDataSeries = OCKDataSeriesConfiguration(
                taskID: task.id,
                legendTitle: "Doxylamine",
                gradientStartColor: .systemGray2,
                gradientEndColor: .systemGray,
                markerSize: 10) { event in
                    event.computeProgress(by: .summingOutcomeValues)
                }

            let insightsCard = OCKCartesianChartViewController(
                plotType: .bar,
                selectedDate: date,
                configurations: [nauseaDataSeries, doxylamineDataSeries],
                store: self.store)

            insightsCard.typedView.headerView.titleLabel.text = "Nausea & Doxylamine Intake"
            insightsCard.typedView.headerView.detailLabel.text = "This Week"
            insightsCard.typedView.headerView.accessibilityLabel = "Nausea & Doxylamine Intake, This Week"
            cards.append(insightsCard)

            /*
             Also create a card that displays a single event.
             The event query passed into the initializer specifies that only
             today's log entries should be displayed by this log task view controller.
             */
            let nauseaCard = OCKButtonLogTaskViewController(query: query,
                                                            store: self.store)
            cards.append(nauseaCard)
            return cards

        default:
            return nil
        }
    }

    private func fetchEvents(on date: Date) async throws -> CareStoreQueryResults<OCKEvent<OCKTask, OCKOutcome>> {
        let (tasks, taskQuery) = await self.fetchTasks(on: date)
        return try streamCareStoreEvents(for: tasks, from: taskQuery)
    }

    private func fetchTasks(on date: Date) async -> ([OCKAnyTask], OCKTaskQuery) {
        var query = OCKTaskQuery(for: date)
        query.excludesTasksWithNoEvents = true
        do {
            let tasks = try await store.fetchAnyTasks(query: query)
            let orderedTasks = TaskID.ordered.compactMap { orderedTaskID in
                tasks.first(where: { $0.id == orderedTaskID }) }
            return (orderedTasks, query)
        } catch {
            Logger.feed.error("\(error, privacy: .public)")
            return ([], query)
        }
    }

    private func streamCareStoreEvents(for tasks: [OCKAnyTask],
                                       // swiftlint:disable:next line_length
                                       from query: OCKTaskQuery) throws -> CareStoreQueryResults<OCKEvent<OCKTask, OCKOutcome>> {
        guard tasks.count > 0 else {
            throw AppError.errorString("No current tasks")
        }
        guard let dateInterval = query.dateInterval else {
            throw AppError.errorString("Task query should have a set date")
        }
        // var events = [CareStoreFetchRequest<OCKAnyEvent, OCKEventQuery>]()
        var eventQuery = OCKEventQuery(dateInterval: dateInterval)
        eventQuery.taskIDs = tasks.map { $0.id }
        guard let store = AppDelegateKey.defaultValue?.store else {
            throw AppError.couldntBeUnwrapped
        }
        return store.events(matching: eventQuery)
        /*if let healthKitStore = AppDelegateKey.defaultValue?.healthKitStore {
            let storeEvents = healthKitStore.events(matching: eventQuery)
            // other.append(storeEvents)
        } */
        /*tasks.forEach {
            eventQuery.taskIDs = [$0.id]
            events.append(CareStoreFetchRequest(query: eventQuery))
        }*/
    }
}

private extension View {
    func formattedHostingController() -> UIHostingController<Self> {
        let viewController = UIHostingController(rootView: self)
        viewController.view.backgroundColor = .clear
        return viewController
    }
}
