//
//  IrisContextSelectionView.swift
//  ArtemisKit
//
//  Created by Senan Aslan on 06.06.26.
//

import DesignLibrary
import SharedModels
import SwiftUI

/// Lets the user scope the next Iris message to a lecture or a (text/programming)
/// exercise of the course. Tapping a row hands the chosen ``SessionContext`` back
/// via ``onSet`` and dismisses — there is no separate confirm step.
struct IrisContextSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: IrisContextSelectionViewModel

    let onSet: (SessionContext) -> Void

    var body: some View {
        NavigationStack {
            DataStateView(data: $viewModel.courseState) {
                await viewModel.loadCourseIfNeeded()
            } content: { _ in
                if viewModel.lectures.isEmpty && viewModel.exercises.isEmpty {
                    ContentUnavailableView(R.string.localizable.noItems(), systemImage: "tray")
                } else {
                    List {
                        if !viewModel.lectures.isEmpty {
                            Section(R.string.localizable.lecturesSection()) {
                                ForEach(viewModel.lectures) { lecture in
                                    ContextRow(title: lecture.title,
                                               isSelected: viewModel.isSelected(lecture: lecture)) {
                                        viewModel.select(lecture: lecture)
                                        apply()
                                    }
                                }
                            }
                        }
                        if !viewModel.exercises.isEmpty {
                            Section(R.string.localizable.exercisesSection()) {
                                ForEach(viewModel.exercises) { exercise in
                                    ContextRow(title: exercise.baseExercise.title,
                                               isSelected: viewModel.isSelected(exercise: exercise)) {
                                        viewModel.select(exercise: exercise)
                                        apply()
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(R.string.localizable.selectTitle())
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $viewModel.searchText)
            .task {
                await viewModel.loadCourseIfNeeded()
            }
        }
    }

    /// Pushes the current pick up to the chat view model and closes the
    /// presentation. Called from a row tap — there is no separate confirm step.
    private func apply() {
        if let selection = viewModel.selection {
            onSet(selection)
        }
        dismiss()
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
