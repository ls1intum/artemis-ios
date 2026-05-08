//
//  MediumWidgetView.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 09.05.26.
//

import SharedModels
import SwiftUI

struct MediumWidgetView: View {
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
                WidgetEventGroup(showSubtitle: false,
                                 events: [nextLecture],
                                 canTakeMoreSpace: nextTutorial == nil)
            }

            if let nextTutorial {
                WidgetEventGroup(showSubtitle: false,
                                 events: [nextTutorial],
                                 canTakeMoreSpace: nextLecture == nil)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, .m)
        .containerRelativeFrame([.vertical, .horizontal], alignment: .topLeading)
    }
}
