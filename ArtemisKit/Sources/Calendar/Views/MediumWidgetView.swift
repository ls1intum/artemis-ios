//
//  MediumWidgetView.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 29.04.26.
//

import DesignLibrary
import SharedModels
import SwiftUI

public struct MediumCalendarWidgetView: View {
    let entry: CalendarWidgetEntry

    public init(entry: CalendarWidgetEntry) {
        self.entry = entry
    }

    public var body: some View {
        if entry.needsConfiguration {
            ContentUnavailableView(R.string.localizable.notConfigured(),
                                   systemImage: "wrench.adjustable",
                                   description: Text(R.string.localizable.configureDetail()))
        } else if entry.error {
            ContentUnavailableView(R.string.localizable.failedLoading(),
                                   systemImage: "antenna.radiowaves.left.and.right.slash")
        } else if entry.calendarEvents.isEmpty {
            Text(R.string.localizable.noUpcomingEvents())
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        } else {
            WidgetEventsView(events: entry.calendarEvents)
        }
    }
}

struct WidgetEventsView: View {
    let events: [DTO.CalendarEvent]

    var nextLecture: DTO.CalendarEvent? {
        events.first { $0._type == .lecture }
    }

    var nextTutorial: DTO.CalendarEvent? {
        events.first { $0._type == .tutorial }
    }

    var body: some View {
        TwoColumnLayout {
            WidgetDueSoonView(events: events)

            if let nextLecture {
                WidgetEventGroup(title: "Next Lecture", showSubtitle: false, events: [nextLecture], color: .teal)
            }

            if let nextTutorial {
                WidgetEventGroup(title: "Next Tutorial", showSubtitle: false, events: [nextTutorial], color: .blue)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, .m)
        .containerRelativeFrame([.vertical, .horizontal], alignment: .topLeading)
    }
}
