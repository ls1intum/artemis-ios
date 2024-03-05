//
//  PathViews.swift
//
//
//  Created by Nityananda Zbil on 05.03.24.
//

import Common
import DesignLibrary
import SharedModels
import SwiftUI

public struct CoursePathView<Content: View>: View {
    @State var viewModel: CoursePathViewModel
    let content: (Course) -> Content

    public var body: some View {
        DataStateView(data: $viewModel.course) {
            await viewModel.loadCourse()
        } content: { course in
            content(course)
        }
        .task {
            await viewModel.loadCourse()
        }
    }
}

public extension CoursePathView {
    init(path: CoursePath, @ViewBuilder content: @escaping (Course) -> Content) {
        self.init(viewModel: CoursePathViewModel(path: path), content: content)
    }
}
