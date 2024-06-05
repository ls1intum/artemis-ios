//
//  CourseGridView.swift
//
//
//  Created by Nityananda Zbil on 29.11.23.
//

import CourseRegistration
import DesignLibrary
import SwiftUI

struct CourseGrid: View {
    private static let layout = [GridItem(.adaptive(minimum: 400, maximum: .infinity), spacing: .l, alignment: .center)]

    @ObservedObject var viewModel: DashboardViewModel
    @State private var isCourseRegistrationPresented = false

    var body: some View {
        DataStateView(data: $viewModel.coursesForDashboard) {
            await viewModel.loadCourses()
        } content: { coursesForDashboard in
            ScrollView {
                LazyVGrid(columns: Self.layout, spacing: .l) {
                    ForEach(coursesForDashboard.courses ?? [], content: CourseGridCell.init)
                }
                .padding(.horizontal, .l)

                HStack {
                    Spacer()
                    Button(R.string.localizable.dashboardRegisterForCourseButton()) {
                        isCourseRegistrationPresented = true
                    }
                    .buttonStyle(ArtemisButton())
                    Spacer()
                }
            }
            .refreshable {
                await viewModel.loadCourses()
            }
        }
        .sheet(isPresented: $isCourseRegistrationPresented) {
            CourseRegistrationView {
                isCourseRegistrationPresented = false
                viewModel.coursesForDashboard = .loading
                Task {
                    await viewModel.loadCourses()
                }
            }
        }
        .task {
            await viewModel.loadCourses()
        }
    }
}

#Preview {
    CourseGrid(viewModel: DashboardViewModel(courseService: CourseServiceStub()))
}
