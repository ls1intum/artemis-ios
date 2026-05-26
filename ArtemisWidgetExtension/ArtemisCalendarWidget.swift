//
//  ArtemisCalendarWidget.swift
//  ArtemisWidgetExtension
//
//  Created by Anian Schleyer on 29.04.26.
//  Copyright © 2026 TUM. All rights reserved.
//

import Calendar
import WidgetKit
import SwiftUI

struct ArtemisCalendarWidget: Widget {
    let kind: String = "ArtemisCalendarWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind,
                               intent: CalendarCourseConfigurationIntent.self,
                               provider: CalendarTimelineProvider()) { entry in
            HomeScreenWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .supportedFamilies([.systemMedium, .systemSmall])
        .configurationDisplayName("Calendar")
        .description("Keep an overview of upcoming events.")
    }
}
