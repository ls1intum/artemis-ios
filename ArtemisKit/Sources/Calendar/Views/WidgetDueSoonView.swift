//
//  WidgetDueSoonView.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 03.05.26.
//

import SharedModels
import SwiftUI

struct WidgetDueSoonView: View {
    let events: [DTO.CalendarEvent]

    init(events: [DTO.CalendarEvent]) {
        let exercises = events.filter {
            switch $0._type {
            case .fileUploadExercise,
                    .modelingExercise,
                    .programmingExercise,
                    .quizExercise,
                    .textExercise:
                true
            default:
                false
            }
        }
        .sorted { lhs, rhs in
            lhs.startDate < rhs.startDate
        }

        let firstDate = exercises.first?.startDate ?? .distantPast

        self.events = exercises.filter {
            // All exercises due within 2 hours of the first one
            $0.startDate < firstDate.addingTimeInterval(60 * 60 * 2)
        }
        .map {
            var event = $0
            if event.title.hasPrefix("Due: ") {
                event.title = String(event.title.dropFirst(5))
            }
            return event
        }
    }

    var body: some View {
        if !events.isEmpty {
            WidgetEventGroup(showSubtitle: true, events: events)
        }
    }
}
