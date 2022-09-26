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
                                               // swiftlint:disable:next line_length
                                               name: Notification.Name(rawValue: Constants.completedFirstSyncAfterLogin),
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
        AppDelegateKey.defaultValue?.store?.synchronize { error in
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
            let tasks = await self.fetchTasks(on: date)
            tasks.compactMap {
                let cards = self.taskViewController(for: $0, on: date)
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
        switch task.id {
        case TaskID.steps:
            let view = NumericProgressTaskView(
                task: task,
                eventQuery: OCKEventQuery(for: date),
                storeManager: self.storeManager)
                .padding([.vertical], 20)
                .careKitStyle(CustomStylerKey.defaultValue)

            return [view.formattedHostingController()]
        case TaskID.stretch:
            return [OCKInstructionsTaskViewController(task: task,
                                                     eventQuery: .init(for: date),
                                                     storeManager: self.storeManager)]

        case TaskID.kegels:
            /*
             Since the kegel task is only scheduled every other day, there will be cases
             where it is not contained in the tasks array returned from the query.
             */
            return [OCKSimpleTaskViewController(task: task,
                                               eventQuery: .init(for: date),
                                               storeManager: self.storeManager)]

        // Create a card for the doxylamine task if there are events for it on this day.
        case TaskID.doxylamine:

            return [OCKChecklistTaskViewController(
                task: task,
                eventQuery: .init(for: date),
                storeManager: self.storeManager)]

        case TaskID.nausea:
            var cards = [UIViewController]()
            // dynamic gradient colors
            let nauseaGradientStart = UIColor { traitCollection -> UIColor in
                return traitCollection.userInterfaceStyle == .light ? #colorLiteral(red: 0.06253327429, green: 0.6597633362, blue: 0.8644603491, alpha: 1) : #colorLiteral(red: 0, green: 0.2858072221, blue: 0.6897063851, alpha: 1)
            }
            let nauseaGradientEnd = UIColor { traitCollection -> UIColor in
                return traitCollection.userInterfaceStyle == .light ? #colorLiteral(red: 0, green: 0.2858072221, blue: 0.6897063851, alpha: 1) : #colorLiteral(red: 0.06253327429, green: 0.6597633362, blue: 0.8644603491, alpha: 1)
            }

            // Create a plot comparing nausea to medication adherence.
            let nauseaDataSeries = OCKDataSeriesConfiguration(
                taskID: "nausea",
                legendTitle: "Nausea",
                gradientStartColor: nauseaGradientStart,
                gradientEndColor: nauseaGradientEnd,
                markerSize: 10,
                eventAggregator: OCKEventAggregator.countOutcomeValues)

            let doxylamineDataSeries = OCKDataSeriesConfiguration(
                taskID: "doxylamine",
                legendTitle: "Doxylamine",
                gradientStartColor: .systemGray2,
                gradientEndColor: .systemGray,
                markerSize: 10,
                eventAggregator: OCKEventAggregator.countOutcomeValues)

            let insightsCard = OCKCartesianChartViewController(
                plotType: .bar,
                selectedDate: date,
                configurations: [nauseaDataSeries, doxylamineDataSeries],
                storeManager: self.storeManager)

            insightsCard.chartView.headerView.titleLabel.text = "Nausea & Doxylamine Intake"
            insightsCard.chartView.headerView.detailLabel.text = "This Week"
            insightsCard.chartView.headerView.accessibilityLabel = "Nausea & Doxylamine Intake, This Week"
            cards.append(insightsCard)

            /*
             Also create a card that displays a single event.
             The event query passed into the initializer specifies that only
             today's log entries should be displayed by this log task view controller.
             */
            let nauseaCard = OCKButtonLogTaskViewController(task: task,
                                                            eventQuery: .init(for: date),
                                                            storeManager: self.storeManager)
            cards.append(nauseaCard)
            return cards

        default:
            return nil
        }
    }

    private func fetchTasks(on date: Date) async -> [OCKAnyTask] {
        var query = OCKTaskQuery(for: date)
        query.excludesTasksWithNoEvents = true
        do {
            let tasks = try await storeManager.store.fetchAnyTasks(query: query)
            let orderedTasks = TaskID.ordered.compactMap { orderedTaskID in
                tasks.first(where: { $0.id == orderedTaskID }) }
            return orderedTasks
        } catch {
            Logger.feed.error("\(error.localizedDescription, privacy: .public)")
            return []
        }
    }
}

private extension View {
    func formattedHostingController() -> UIHostingController<Self> {
        let viewController = UIHostingController(rootView: self)
        viewController.view.backgroundColor = .clear
        return viewController
    }
}
