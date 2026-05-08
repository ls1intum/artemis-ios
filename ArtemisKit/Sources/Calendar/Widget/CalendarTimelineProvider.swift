//
//  CalendarTimelineProvider.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 29.04.26.
//

import APIClient
import SharedModels
import WidgetKit

public struct CalendarTimelineProvider: AppIntentTimelineProvider {

    public init() {}

    public func placeholder(in context: Context) -> CalendarWidgetEntry {
        CalendarWidgetEntry(date: Date(), needsConfiguration: false)
    }

    public func snapshot(for configuration: CalendarCourseConfigurationIntent, in context: Context) async -> CalendarWidgetEntry {
        CalendarWidgetEntry(date: Date(),
                            needsConfiguration: false,
                            calendarEvents: [
                                .init(_type: .lecture,
                                      title: "Software Engineering",
                                      startDate: .tomorrow),
                                .init(_type: .programmingExercise,
                                      title: "W04E01 Broker",
                                      startDate: .tomorrow),
                                .init(_type: .programmingExercise,
                                      title: "W04E02 Async ID Generation",
                                      startDate: .tomorrow),
                                .init(_type: .tutorial,
                                      title: "Group 7",
                                      startDate: .now)
                            ]
        )
    }

    public func timeline(for configuration: CalendarCourseConfigurationIntent,
                         in context: Context) async -> Timeline<CalendarWidgetEntry> {

        guard let courseId = configuration.course?.id else {
            return Timeline(entries: [
                CalendarWidgetEntry(date: .now, needsConfiguration: true)
            ], policy: .after(.now.addingTimeInterval(60 * 30)))
        }

        var entries: [CalendarWidgetEntry] = []

        guard let events = await fetchEventsForCurrentAndNextMonth(courseId: courseId) else {
            return Timeline(entries: [
                CalendarWidgetEntry(date: .now, needsConfiguration: false)
            ], policy: .after(.now.addingTimeInterval(60 * 30)))
        }

        let allEvents = events.sorted {
            $0.startDate < $1.startDate
        }

        let startDates = allEvents.compactMap(\.startDate)
        let endDates = allEvents.compactMap(\.endDate)
        for date in startDates + endDates {
            // Always update within a minute of something starting or ending
            let entry = CalendarWidgetEntry(date: date.addingTimeInterval(60),
                                            needsConfiguration: false,
                                            calendarEvents: allEvents)
            entries.append(entry)
        }

        if entries.isEmpty {
            entries.append(CalendarWidgetEntry(date: .now,
                                               needsConfiguration: false,
                                               calendarEvents: []))
        }

        // Timeline that refreshes every 12 hours
        return Timeline(entries: entries,
                        policy: .after(.now.addingTimeInterval(60 * 60 * 12)))
    }

    private func fetchEventsForCurrentAndNextMonth(courseId: Int) async -> [DTO.CalendarEvent]? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"

        let currentMonth = formatter.string(from: .now)
        let nextMonth = formatter.string(from: Calendar.current.date(byAdding: DateComponents(month: 1), to: .now) ?? .now)

        let events = await APIClient().call { client in
            try await client.getCalendarEventsOverlappingMonths(
                .init(path: .init(courseId: Int64(courseId)),
                      query: .init(monthKeys: [currentMonth, nextMonth],
                                   timeZone: "Europe/Berlin",
                                   language: .english))
            )
            .ok.body.json.additionalProperties
        }.value

        if let allEvents = events?.values.flatMap({ $0 }) {
            return allEvents.filter {
                ($0.endDate ?? $0.startDate) > .now
            }
        }
        return nil
    }
}
