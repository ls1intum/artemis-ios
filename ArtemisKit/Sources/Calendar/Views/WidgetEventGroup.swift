//
//  WidgetEventGroup.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 03.05.26.
//

import SharedModels
import SwiftUI

struct WidgetEventGroup: View {
    let title: String
    let showSubtitle: Bool
    let events: [DTO.CalendarEvent]
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: .s) {
            Text(title)
                .font(.title2.bold())
                .foregroundStyle(.orange)

            if showSubtitle {
                Text(events.first?.startDate ?? .distantPast, style: .relative)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .offset(y: .xs * -1)
            }

            LazyVGrid(columns: [.init(.fixed(.s)), .init(.flexible(), alignment: .leading)],
                      spacing: .s) {
                Capsule()
                    .fill(color)

                VStack(alignment: .leading) {
                    ForEach(events, id: \.hashValue) { event in
                        Text(event.title)
                            .lineLimit(events.count == 1 ? 2 : 1)
                        if events.count == 1 && !showSubtitle {
                            Text(event.startDate, style: .date)
                        }
                    }
                }
                .font(.subheadline)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
