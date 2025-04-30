//
//  InsightsView.swift
//  OCKSample
//
//  Created by Corey Baker on 4/17/25.
//  Copyright © 2025 Network Reconnaissance Lab. All rights reserved.
//

import CareKit
import CareKitEssentials
import CareKitStore
import CareKitUI
import SwiftUI

struct InsightsView: View {

	@CareStoreFetchRequest(query: query()) private var events
	@State var intervalSelected = 0 // Default to week since chart isn't working for others.
	@State var chartInterval = DateInterval()
	@State var period: PeriodComponent = .day
	@State var configurations: [CKEDataSeriesConfiguration] = []
	@State var sortedTaskIDs: [String: Int] = [:]

    var body: some View {
		ScrollView {
			dateIntervalSegmentView
			.padding()

			// This is for loop is useful when you want a chart for
			// for every task which may not always be the case.
			ForEach(orderedEvents) { event in
				let eventResult = event.result

				if eventResult.task.id != TaskID.doxylamine
					&& eventResult.task.id != TaskID.nausea {

					// dynamic gradient colors
					let meanGradientStart = Color(TintColorFlipKey.defaultValue)
					let meanGradientEnd = Color.accentColor

					// Can add muliple plots on a single
					// chart by adding multiple configurations.
					let meanConfiguration = CKEDataSeriesConfiguration(
						taskID: eventResult.task.id,
						dataStrategy: .mean,
						mark: .bar,
						legendTitle: String(localized: "AVERAGE"),
						showMarkWhenHighlighted: true,
						showMeanMark: false,
						showMedianMark: false,
						color: meanGradientEnd,
						gradientStartColor: meanGradientStart,
					) { event in
						event.computeProgress(by: .maxOutcomeValue())
					}

					let sumConfiguration = CKEDataSeriesConfiguration(
						taskID: eventResult.task.id,
						dataStrategy: .sum,
						mark: .bar,
						legendTitle: String(localized: "TOTAL"),
						color: Color(TintColorFlipKey.defaultValue) // Set to app color.
					) { event in
						event.computeProgress(by: .maxOutcomeValue())
					}

					CareKitEssentialChartView(
						title: eventResult.title,
						subtitle: subtitle,
						dateInterval: $chartInterval,
						period: $period,
						configurations: [
							meanConfiguration,
							sumConfiguration
						]
					)

				} else if eventResult.task.id == TaskID.doxylamine {
					// Example of showing nausea vs doxlymine

					// dynamic gradient colors
					let nauseaGradientStart = Color(TintColorFlipKey.defaultValue)
					let nauseaGradientEnd = Color.accentColor

					let nauseaConfiguration = CKEDataSeriesConfiguration(
						taskID: TaskID.nausea,
						dataStrategy: .sum,
						mark: .bar,
						legendTitle: String(localized: "NAUSEA"),
						showMarkWhenHighlighted: true,
						showMeanMark: true,
						showMedianMark: false,
						color: nauseaGradientEnd,
						gradientStartColor: nauseaGradientStart,
						stackingMethod: .unstacked
					) { event in
						// This event occurs all-day and can be submitted
						// multiple times, since we want to understand
						// the "total" amount of times a patient experiences
						// nausea, we sum the outcomes for each event.
						event.computeProgress(by: .summingOutcomeValues())
					}

					let doxylamineConfiguration = CKEDataSeriesConfiguration(
						taskID: eventResult.task.id,
						dataStrategy: .sum,
						mark: .bar,
						legendTitle: String(localized: "DOXYLAMINE"),
						color: .gray,
						gradientStartColor: .gray.opacity(0.3),
						stackingMethod: .unstacked,
						symbol: .diamond,
						interpolation: .catmullRom
					) { event in
						event.computeProgress(by: .averagingOutcomeValues())
					}

					CareKitEssentialChartView(
						title: String(localized: "NAUSEA_DOXYLAMINE_INTAKE"),
						subtitle: subtitle,
						dateInterval: $chartInterval,
						period: $period,
						configurations: [
							nauseaConfiguration,
							doxylamineConfiguration
						]
					)
				}
			}

			Spacer()
		}
		.onAppear {
			let taskIDs = TaskID.orderedWatchOS
			sortedTaskIDs = computeTaskIDOrder(taskIDs: taskIDs)
			events.query.taskIDs = taskIDs
			events.query.dateInterval = eventQueryInterval
			setupChartPropertiesForSegmentSelection(intervalSelected)
		}
		#if os(iOS)
		.onChange(of: intervalSelected) { intervalSegmentValue in
			setupChartPropertiesForSegmentSelection(intervalSegmentValue)
		}
		#else
		.onChange(of: intervalSelected, initial: true) { _, newSegmentValue in
			setupChartPropertiesForSegmentSelection(newSegmentValue)
		}
		#endif
    }

	private var orderedEvents: [CareStoreFetchedResult<OCKAnyEvent>] {
		events.latest.sorted(by: { left, right in
			let leftTaskID = left.result.task.id
			let rightTaskID = right.result.task.id

			return sortedTaskIDs[leftTaskID] ?? 0 < sortedTaskIDs[rightTaskID] ?? 0
		})
	}

	private var dateIntervalSegmentView: some View {
		Picker(
			"CHOOSE_DATE_INTERVAL",
			selection: $intervalSelected.animation()
		) {
			Text("TODAY")
				.tag(0)
			Text("WEEK")
				.tag(1)
			Text("MONTH")
				.tag(2)
			Text("YEAR")
				.tag(3)
		}
		#if !os(watchOS)
		.pickerStyle(.segmented)
		#else
		.pickerStyle(.automatic)
		#endif
	}

	private var subtitle: String {
		switch intervalSelected {
		case 0:
			return String(localized: "TODAY")
		case 1:
			return String(localized: "WEEK")
		case 2:
			return String(localized: "MONTH")
		case 3:
			return String(localized: "YEAR")
		default:
			return String(localized: "WEEK")
		}
	}

	// Currently only look for events for the last.
	// We don't need to vary this because it's only
	// used to find taskID's. The chartInterval will
	// find all of the needed data for the chart.
	private var eventQueryInterval: DateInterval {
		let interval = Calendar.current.dateInterval(
			of: .weekOfYear,
			for: Date()
		)!
		return interval
	}

	private func setupChartPropertiesForSegmentSelection(_ segmentValue: Int) {
		let now = Date()
		let calendar = Calendar.current
		// This changes the interval of what will be
		// shown in the graph.
		switch segmentValue {
		case 0:
			let startOfDay = Calendar.current.startOfDay(
				for: now
			)
			let interval = DateInterval(
				start: startOfDay,
				end: now
			)

			period = .day
			chartInterval = interval

		case 1:
			let startDate = calendar.date(
				byAdding: .weekday,
				value: -7,
				to: now
			)!
			period = .week
			chartInterval = DateInterval(start: startDate, end: now)

		case 2:
			let startDate = calendar.date(
				byAdding: .month,
				value: -1,
				to: now
			)!
			period = .month
			chartInterval = DateInterval(start: startDate, end: now)

		case 3:
			let startDate = calendar.date(
				byAdding: .year,
				value: -1,
				to: now
			)!
			period = .month
			chartInterval = DateInterval(start: startDate, end: now)

		default:
			let startDate = calendar.date(
				byAdding: .weekday,
				value: -7,
				to: now
			)!
			period = .week
			chartInterval = DateInterval(start: startDate, end: now)

		}
	}

	private func computeTaskIDOrder(taskIDs: [String]) -> [String: Int] {
		// Tie index values to TaskIDs.
		let sortedTaskIDs = taskIDs.enumerated().reduce(into: [String: Int]()) { taskDictionary, task in
			taskDictionary[task.element] = task.offset
		}

		return sortedTaskIDs
	}

	static func query() -> OCKEventQuery {
		let query = OCKEventQuery(dateInterval: .init())
		return query
	}
}

#Preview {
    InsightsView()
		.environment(\.careStore, Utility.createPreviewStore())
		.careKitStyle(Styler())
}
