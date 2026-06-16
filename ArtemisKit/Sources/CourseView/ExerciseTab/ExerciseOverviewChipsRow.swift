//
//  ExerciseOverviewChipsRow.swift
//  ArtemisKit
//
//  Created by Eylul Naz Can on 29.04.2025.
//

import SwiftUI
import SharedModels
import Common
import DesignLibrary

struct ExerciseOverviewChipsRow: View {
    let exercise: Exercise
    let score: String
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private let relFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .full
        return f
    }()

    // use centered FlowLayout if vertical side of device is not compact (e.g., iPad or horizontally located mobile device)
    // else show the LazyVGrid
    private var shouldLayout: Bool {
        horizontalSizeClass == .regular || verticalSizeClass == .compact
    }

    var body: some View {
        let columns = [
            GridItem(.flexible(), spacing: .m, alignment: .top),
            GridItem(.flexible(), spacing: .m, alignment: .top)
        ]

        if shouldLayout {
            FlowLayout(spacing: .s, isCentered: true) {
                gridChips
                specialChips
            }.padding(.horizontal, .m)
        } else {
            VStack(spacing: .m) {
                // Display standard exercise metrics
                LazyVGrid(columns: columns, alignment: .leading, spacing: .m) {
                    gridChips
                }
                // Render all categories using custom FlowLayout
                specialChips
            }
            .padding(.horizontal, .m)
        }
    }

    @ViewBuilder private var gridChips: some View {
        // Points Chip
        let maxPoints = exercise.baseExercise.maxPoints
        TwoLineChip(title: R.string.localizable.pointsTitle()) {
            Text(R.string.localizable.points(score, maxPoints?.clean ?? "0"))
        }

        // Submission Chip
        if let due = exercise.baseExercise.dueDate {
            let remaining = due.timeIntervalSinceNow
            let isLessThanADay = remaining > 0 && remaining < 86_400 // 24 * 60 * 60

            let value = (remaining > 0 && abs(remaining) < 7 * 24 * 60 * 60)
            ? relFormatter.localizedString(for: due, relativeTo: .now)
            : due.mediumDateShortTime

            let title = remaining > 0
            ? R.string.localizable.submissionDueTitle()
            : R.string.localizable.submissionClosedTitle()

            TwoLineChip(title: title) {
                Text(value)
                    .foregroundColor(isLessThanADay ? .red : Color.Artemis.primaryLabel)
            }
        }

        // Status Chip
        TwoLineChip(title: R.string.localizable.statusTitle()) {
            SubmissionResultStatusView(exercise: exercise, length: .short)
        }

        // Difficulty Chip
        if let difficulty = exercise.baseExercise.difficulty {
            TwoLineChip(title: R.string.localizable.difficultyTitle()) {
                DifficultyBar(difficulty: difficulty)
            }
        }
    }

    // ---------------------------------------------------------------------------
    // Categories / special badges chip
    // Show WHEN at least one of:
    //   • exercise.releaseDate is in the future          → “Not released”
    //   • includedInOverallScore != .includedCompletely  → that value’s description
    //   • exercise.categories != nil                     → up to 3 category badges
    // ---------------------------------------------------------------------------
    @ViewBuilder private var specialChips: some View {
        let specialBadges: [AnyView] = {
            var badges: [AnyView] = []
            // 1. Not released
            if let release = exercise.baseExercise.releaseDate, release > .now {
                badges.append(
                    AnyView(Chip(text: R.string.localizable.notReleased(),
                                 backgroundColor: Color.Artemis.badgeWarningColor, padding: .s))
                )
            }
            // 2. Included-in-overall-score
            if exercise.baseExercise.includedInOverallScore != .includedCompletely {
                let includedInScore = exercise.baseExercise.includedInOverallScore
                badges.append(
                    AnyView(Chip(text: includedInScore.description,
                                 backgroundColor: includedInScore.color, padding: .s))
                )
            }
            // 3. Categories (max 3, then “+ n more”)
            if let cats = exercise.baseExercise.categories, !cats.isEmpty {
                let maxVisibleCategories = 3
                for cat in cats.prefix(maxVisibleCategories) {
                    badges.append(
                        AnyView(Chip(text: cat.category,
                                     backgroundColor: UIColor(hexString: cat.colorCode).suColor,
                                     padding: .s))
                    )
                }
                let remainder = cats.count - min(cats.count, maxVisibleCategories)
                if remainder > 0 {
                    badges.append(
                        AnyView(Chip(text: "+\(remainder) more",
                                     backgroundColor: Color.Artemis.badgeSecondaryColor,
                                     padding: .s))
                    )
                }
            }
            return badges
        }()
        if !specialBadges.isEmpty {
            TwoLineChip(title: R.string.localizable.categoryTitle(), lineLimit: nil) {
                FlowLayout(spacing: .xs) {
                    ForEach(Array(specialBadges.enumerated()), id: \.offset) { _, view in
                        view
                        // disallow text wrapping instide the chip and add "..."
                            .lineLimit(1)
                            .frame(maxWidth: 220, alignment: .leading)
                            .padding(.bottom, .s)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

private struct TwoLineChip<Content: View>: View {
    let title: String
    var lineLimit: Int? = 1
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: .s) {
            Text(title)
                .font(.footnote.weight(.bold))
                .foregroundColor(Color.Artemis.buttonDisabledColor)
                .lineLimit(lineLimit)
                .frame(maxWidth: .infinity, alignment: .leading)

            content
                .font(.footnote.weight(.bold))
                .foregroundColor(Color.Artemis.primaryLabel)
                .lineLimit(lineLimit)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, .m)
        .padding(.vertical, .s)
        .frame(minHeight: 50)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.Artemis.cardBorderColor, lineWidth: 1)
        )
    }
}

struct DifficultyBar: View {
    let difficulty: Difficulty

    private var fillCount: Int {
        switch difficulty {
        case .EASY: return 1
        case .MEDIUM: return 2
        case .HARD: return 3
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...3, id: \.self) { index in
                RoundedRectangle(cornerRadius: 4)
                    .frame(width: 20, height: 10)
                    .foregroundColor(index <= fillCount ? difficulty.color : difficulty.color.opacity(0.2))
            }
        }
    }
}
