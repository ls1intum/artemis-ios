//
//  IrisContextSelectionView.swift
//  ArtemisKit
//
//  Created by Senan Aslan on 06.06.26.
//

import DesignLibrary
import Navigation
import SharedModels
import SwiftUI

/// Lets the user scope the next Iris message to a lecture or a (text/programming)
/// exercise of the course. Tapping a row hands the chosen ``SessionContext`` back
/// via ``onSet`` and dismisses — there is no separate confirm step.
struct IrisContextSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: IrisContextSelectionViewModel

    let courseId: Int
    /// The context currently active in the chat — drives the row checkmark.
    let currentSelection: SessionContext?
    let onSet: (SessionContext) -> Void

    var body: some View {
        NavigationStack {
            CoursePathView(path: CoursePath(id: courseId)) { course in
                content(for: course)
            }
            .navigationTitle(R.string.localizable.selectTitle())
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $viewModel.searchText)
        }
    }

    @ViewBuilder
    private func content(for course: Course) -> some View {
        let lectures = viewModel.lectures(in: course)
        let exercises = viewModel.exercises(in: course)
        if lectures.isEmpty && exercises.isEmpty {
            ContentUnavailableView(R.string.localizable.noItems(), systemImage: "tray")
        } else {
            List {
                if !lectures.isEmpty {
                    Section(R.string.localizable.lecturesSection()) {
                        ForEach(lectures) { lecture in
                            ContextRow(title: lecture.title,
                                       isSelected: viewModel.isSelected(lecture: lecture, current: currentSelection)) {
                                onSet(viewModel.context(for: lecture))
                                dismiss()
                            }
                        }
                    }
                }
                if !exercises.isEmpty {
                    Section(R.string.localizable.exercisesSection()) {
                        ForEach(exercises) { exercise in
                            ContextRow(title: exercise.baseExercise.title,
                                       isSelected: viewModel.isSelected(exercise: exercise, current: currentSelection)) {
                                onSet(viewModel.context(for: exercise))
                                dismiss()
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct ContextRow: View {
    let title: String?
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                Text(title ?? R.string.localizable.untitled())
                    .foregroundStyle(.primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}
