//
//  MediumWidgetView.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 29.04.26.
//

import DesignLibrary
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
            Text("\(entry.calendarEvents.count) upcoming events (TODO: Design)")
        }
    }
}
