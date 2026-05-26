//
//  WidgetEventGroup.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 03.05.26.
//

import SharedModels
import SwiftUI

struct WidgetEventGroup: View {
    let showSubtitle: Bool
    let events: [DTO.CalendarEvent]
    var canTakeMoreSpace = false

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
                            .lineLimit(canTakeMoreSpace ? 2 : 1)

                        timeView(for: event)
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.subheadline)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func timeView(for event: DTO.CalendarEvent) -> some View {
        if events.count == 1 && !showSubtitle {
            Text(event.startDate, style: .date)
            if canTakeMoreSpace {
                HStack(alignment: .firstTextBaseline, spacing: .s) {
                    Text(event.startDate, style: .time)
                    if let endDate = event.endDate {
                        Text("-")
                        Text(endDate, style: .time)
                    }
                }
            }
        }
    }

    private var title: String {
        switch events.first?._type {
        case .fileUploadExercise, .modelingExercise, .programmingExercise, .quizExercise, .textExercise:
            R.string.localizable.dueSoon()
        case .lecture:
            R.string.localizable.nextLecture()
        case .tutorial:
            R.string.localizable.nextTutorial()
        default:
            ""
        }
    }

    private var color: Color {
        switch events.first?._type {
        case .fileUploadExercise, .modelingExercise, .programmingExercise, .quizExercise, .textExercise:
                .indigo
        case .lecture:
                .teal
        case .tutorial:
                .blue
        default:
                .gray
        }
    }
}
