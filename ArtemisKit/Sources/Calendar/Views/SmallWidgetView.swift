//
//  SmallWidgetView.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 09.05.26.
//

import SharedModels
import SwiftUI

struct SmallWidgetView: View {
    let events: [DTO.CalendarEvent]

    var nextEvent: DTO.CalendarEvent? {
        events.first
    }

    var body: some View {
        Group {
            if let nextEvent {
                switch nextEvent._type {
                case .fileUploadExercise, .modelingExercise, .programmingExercise, .quizExercise, .textExercise:
                    WidgetDueSoonView(events: events)
                default:
                    WidgetEventGroup(showSubtitle: false, events: [nextEvent], canTakeMoreSpace: true)
                }
            }
        }
        .padding()
        .containerRelativeFrame([.vertical, .horizontal], alignment: .topLeading)
    }
}
