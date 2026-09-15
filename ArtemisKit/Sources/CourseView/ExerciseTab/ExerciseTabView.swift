//
//  ExerciseTabView.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 16.09.26.
//

import Common
import DesignLibrary
import SwiftUI

struct ExerciseTabView: View {
    @Bindable var viewModel: CourseViewModel

    var body: some View {
        DataStateView(data: $viewModel.exercisesOverview) {
            await viewModel.refreshExercises()
        } content: { _ in
            ExerciseListView(viewModel: viewModel)
        }
        .task(id: "loadExercises") {
            if case .done = viewModel.exercisesOverview {
                return
            }
            await viewModel.refreshExercises()
        }
    }
}
