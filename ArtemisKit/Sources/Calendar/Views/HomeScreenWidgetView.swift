//
//  HomeScreenWidgetView.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 29.04.26.
//

import SharedModels
import SwiftUI

public struct HomeScreenWidgetView: View {
    @Environment(\.widgetFamily) private var family

    let entry: CalendarWidgetEntry

    public init(entry: CalendarWidgetEntry) {
        self.entry = entry
    }

    public var body: some View {
        let i18n = R.string.localizable
        if entry.needsConfiguration {
            ContentUnavailableView(isSmall ? i18n.notConfiguredShort() : i18n.notConfigured(),
                                   systemImage: "wrench.adjustable",
                                   description: Text(isSmall ? i18n.configureDetailShort() : i18n.configureDetail()))
        } else if entry.error {
            ContentUnavailableView(isSmall ? i18n.failedLoadingShort() : i18n.failedLoading(),
                                   systemImage: "antenna.radiowaves.left.and.right.slash")
        } else if upcomingEvents.isEmpty {
            Text(isSmall ? i18n.noUpcomingEventsShort() : i18n.noUpcomingEvents())
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        } else {
            if isSmall {
                SmallWidgetView(events: upcomingEvents)
            } else {
                MediumWidgetView(events: upcomingEvents)
            }
        }
    }

    private var upcomingEvents: [DTO.CalendarEvent] {
        entry.calendarEvents.filter { event in
            (event.endDate ?? event.startDate) > entry.date && event._type != .exam
        }
    }

    private var isSmall: Bool {
        family == .systemSmall
    }
}
