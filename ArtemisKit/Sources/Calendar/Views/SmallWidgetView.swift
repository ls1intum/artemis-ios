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
                WidgetEventGroup(title: R.string.localizable.nextLecture(),
                                 showSubtitle: false,
                                 events: [nextLecture],
                                 color: .teal,
                                 canTakeMoreSpace: nextTutorial == nil)
            }

            if let nextTutorial {
                WidgetEventGroup(title: R.string.localizable.nextTutorial(),
                                 showSubtitle: false,
                                 events: [nextTutorial],
                                 color: .blue,
                                 canTakeMoreSpace: nextLecture == nil)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, .m)
        .containerRelativeFrame([.vertical, .horizontal], alignment: .topLeading)
    }
}
