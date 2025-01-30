//
//  CourseGridView.swift
//
//
//  Created by Nityananda Zbil on 29.11.23.
//

import CourseRegistration
import DesignLibrary
import SharedModels
import SwiftUI

struct CourseGrid: View {
    private static let layout = [GridItem(.adaptive(minimum: 380, maximum: .infinity), spacing: .l, alignment: .center)]

    @ObservedObject var viewModel: DashboardViewModel
    @State private var isCourseRegistrationPresented = false

    private var recentCourses: [CourseForDashboardDTO] {
        guard let courses = viewModel.coursesForDashboard.value?.courses else { return [] }
        return courses.filter { viewModel.recentCourseIds.contains($0.id) }
    }

    var body: some View {
        DataStateView(data: $viewModel.coursesForDashboard) {
            await viewModel.loadCourses()
        } content: { coursesForDashboard in
            ScrollView {
                if !recentCourses.isEmpty {
                    Text(R.string.localizable.recentlyAccessed())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.title.bold())

                    LazyVGrid(columns: Self.layout, spacing: .l) {
                        ForEach(recentCourses) { course in
                            CourseGridCell(courseForDashboard: course, viewModel: viewModel)
                        }
                    }

                    Text(R.string.localizable.allCourses())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.title.bold())
                        .padding(.top, .l)
                }
                LazyVGrid(columns: Self.layout, spacing: .l) {
                    ForEach(coursesForDashboard.courses ?? []) { course in
                        CourseGridCell(courseForDashboard: course, viewModel: viewModel)
                    }
                }

                HStack {
                    Spacer()
                    Button(R.string.localizable.dashboardRegisterForCourseButton()) {
                        isCourseRegistrationPresented = true
                    }
                    .buttonStyle(ArtemisButton())
                    Spacer()
                }
            }
            .contentMargins(.horizontal, .l, for: .scrollContent)
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
