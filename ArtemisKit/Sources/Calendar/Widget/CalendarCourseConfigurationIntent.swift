//
//  CalendarCourseConfigurationIntent.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 29.04.26.
//

import AppIntents
import WidgetKit

public struct CalendarCourseConfigurationIntent: WidgetConfigurationIntent {
    public static var title: LocalizedStringResource = "Select course"

    @Parameter(title: "Course")
    var course: Course?

    public init() {}
}
