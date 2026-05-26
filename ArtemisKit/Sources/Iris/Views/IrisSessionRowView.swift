//
//  IrisSessionRowView.swift
//  ArtemisKit
//
//  Created by Senan Aslan on 25.05.26.
//

import SwiftUI

struct IrisSessionRowView: View {
    let session: IrisSessionDTO

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: modeIcon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(session.title ?? "New Chat")
                    .lineLimit(1)

                if let entityName = session.entityName {
                    Text(entityName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Text(session.creationDate, style: .date)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var modeIcon: String {
        switch session.mode {
        case .textExercise, .programmingExercise:
            "curlybraces"
        case .course:
            "graduationcap"
        case .lecture:
            "character.book.closed"
        case .tutorSuggestion:
            "lightbulb"
        case .unknown:
            "questionmark"
        }
    }
}
