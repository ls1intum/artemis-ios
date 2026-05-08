//
//  CalendarWidgetEntry.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 29.04.26.
//

import SharedModels
import WidgetKit

public struct CalendarWidgetEntry: TimelineEntry {
    public let date: Date
    let needsConfiguration: Bool
    let error: Bool
    let calendarEvents: [DTO.CalendarEvent]

    public init(date: Date, needsConfiguration: Bool, error: Bool = false, calendarEvents: [DTO.CalendarEvent] = []) {
        self.date = date
        self.needsConfiguration = needsConfiguration
        self.error = error
        self.calendarEvents = calendarEvents
    }
}
