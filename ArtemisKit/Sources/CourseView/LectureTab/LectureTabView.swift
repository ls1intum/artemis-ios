//
//  LectureTabView.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 16.09.26.
//

import Common
import DesignLibrary
import SwiftUI

struct LectureTabView: View {
    @ObservedObject var viewModel: CourseViewModel
    let showFaqButton: Bool

    var body: some View {
        DataStateView(data: $viewModel.lecturesOverview) {
            await viewModel.refreshLectures()
        } content: { _ in
            LectureListView(viewModel: viewModel, showFaqButton: showFaqButton)
        }
        .task(id: "loadLectures") {
            if case .done = viewModel.lecturesOverview {
                return
            }
            await viewModel.refreshLectures()
        }
    }
}
