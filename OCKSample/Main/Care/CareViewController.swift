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

import CareKit
import CareKitEssentials
import CareKitStore
import CareKitUI
import os.log
import SwiftUI
import UIKit

// swiftlint:disable type_body_length

@MainActor
class CareViewController: OCKDailyPageViewController {

    private var isSyncing = false
    private var isLoading = false
    private var accentColor: Color {
        Color(TintColorKey.defaultValue)
    }
    private var style: Styler {
        CustomStylerKey.defaultValue
    }

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
        self.reload()
    }

    /*
     This will be called each time the selected date changes.
     Use this as an opportunity to rebuild the content shown to the user.
     */
    override func dailyPageViewController(
        _ dailyPageViewController: OCKDailyPageViewController,
        prepare listViewController: OCKListViewController,
        for date: Date
    ) {
        self.isLoading = true

        // Always call this method to ensure dates for
        // queries are correct.
        let date = modifyDateIfNeeded(date)
        let isCurrentDay = isSameDay(as: date)

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

        fetchAndDisplayTasks(on: listViewController, for: date)
    }

    private func isSameDay(as date: Date) -> Bool {
        Calendar.current.isDate(
            date,
            inSameDayAs: Date()
        )
    }

    private func modifyDateIfNeeded(_ date: Date) -> Date {
        guard date < .now else {
            return date
        }
        guard !isSameDay(as: date) else {
            return .now
        }
        return date.endOfDay
    }

    private func fetchAndDisplayTasks(
        on listViewController: OCKListViewController,
        for date: Date
    ) {
        Task {
            let tasks = await self.fetchTasks(on: date)
            appendTasks(tasks, to: listViewController, date: date)
        }
    }

    private func taskViewControllers(
        _ task: OCKAnyTask,
        on date: Date
    ) -> [UIViewController]? {

        var query = OCKEventQuery(for: date)
        query.taskIDs = [task.id]

        switch task.id {
        case TaskID.steps:
            let card = EventQueryView<NumericProgressTaskView>(
                query: query
            )
            .formattedHostingController()

            return [card]

        case TaskID.stretch:
            let card = EventQueryView<InstructionsTaskView>(
                query: query
            )
            .formattedHostingController()

            return [card]

        case TaskID.kegels:
            /*
             Since the kegel task is only scheduled every other day, there will be cases
             where it is not contained in the tasks array returned from the query.
             */
            let card = EventQueryView<SimpleTaskView>(
                query: query
            )
            .formattedHostingController()

            return [card]

        // Create a card for the doxylamine task if there are events for it on this day.
        case TaskID.doxylamine:

            // This is a UIKit based card.
            let card = OCKChecklistTaskViewController(
                query: query,
                store: self.store
            )

            return [card]

        case TaskID.nausea:

            let title = String(localized: "NAUSEA_DOXYLAMINE_INTAKE")
            let subtitle = String(localized: "THIS_WEEK")
            let duration = Calendar
                .current
                .dateIntervalOfWeek(for: Date())

            // dynamic gradient colors
            let nauseaGradientStart = Color(TintColorFlipKey.defaultValue)
            let nauseaGradientEnd = accentColor

            let nauseaDataSeries = CKEDataSeriesConfiguration(
                taskID: task.id,
                mark: .bar,
                legendTitle: String(localized: "NAUSEA"),
                color: nauseaGradientEnd,
                gradientStartColor: nauseaGradientStart,
                stackingMethod: .unstacked
            ) { event in
                event.computeProgress(by: .summingOutcomeValues)
            }

            let doxylamineDataSeries = CKEDataSeriesConfiguration(
                taskID: TaskID.doxylamine,
                mark: .bar,
                legendTitle: String(localized: "DOXYLAMINE"),
                color: Color(UIColor.systemGray2),
                gradientStartColor: .gray,
                stackingMethod: .unstacked
            ) { event in
                event.computeProgress(by: .summingOutcomeValues)
            }

            let configurations = [
                nauseaDataSeries,
                doxylamineDataSeries
            ]

            // This is a SwiftUI View Chart.
            let chart = CareEssentialChartView(
                title: title,
                subtitle: subtitle,
                dateInterval: duration,
                period: .day,
                configurations: configurations
            ).formattedHostingController()

            /*
             Also create a card (UIKit view) that displays a single event.
             The event query passed into the initializer specifies that only
             today's log entries should be displayed by this log task view controller.
             */
            let nauseaCard = OCKButtonLogTaskViewController(
                query: query,
                store: self.store
            )

            let cards: [UIViewController] = [
                chart,
                nauseaCard
            ]

            return cards

        default:
            return nil
        }
    }

    private func appendTasks(
        _ tasks: [OCKAnyTask],
        to listViewController: OCKListViewController,
        date: Date
    ) {
        let isCurrentDay = isSameDay(as: date)
        tasks.compactMap {
            let cards = self.taskViewControllers(
                $0,
                on: date
            )
            cards?.forEach {
                if let carekitView = $0.view as? OCKView {
                    carekitView.customStyle = style
                }
                $0.view.isUserInteractionEnabled = isCurrentDay
                $0.view.alpha = !isCurrentDay ? 0.4 : 1.0
            }
            return cards
        }.forEach { (cards: [UIViewController]) in
            cards.forEach {
                let card = $0
                DispatchQueue.main.async {
                    listViewController.appendViewController(card, animated: true)
                }
            }
        }
        DispatchQueue.main.async {
            self.isLoading = false
        }
    }

    private func fetchTasks(on date: Date) async -> [OCKAnyTask] {
        var query = OCKTaskQuery(for: date)
        query.excludesTasksWithNoEvents = true
        do {
            let tasks = try await store.fetchAnyTasks(query: query)
            let orderedTasks = TaskID.ordered.compactMap { orderedTaskID in
                tasks.first(where: { $0.id == orderedTaskID })
            }
            return orderedTasks
        } catch {
            Logger.feed.error("Could not fetch tasks: \(error, privacy: .public)")
            return []
        }
    }
}

private extension View {
    /// Convert SwiftUI view to UIKit view.
    func formattedHostingController() -> UIHostingController<Self> {
        let viewController = UIHostingController(rootView: self)
        viewController.view.backgroundColor = .clear
        return viewController
    }
}
