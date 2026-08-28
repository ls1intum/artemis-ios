//
//  CourseGridView.swift
//
//
//  Created by Nityananda Zbil on 29.11.23.
//

import CourseRegistration
import DesignLibrary
import ProfileInfo
import Search
import SharedModels
import SwiftUI

struct CourseGrid: View {
    private static let layout = [GridItem(.adaptive(minimum: 380, maximum: .infinity), spacing: .l, alignment: .center)]
    let namespace: Namespace.ID

    @FeatureAvailability(.globalSearch) private var globalSearchAvailable

    @Bindable var viewModel: DashboardViewModel
    @State private var isCourseRegistrationPresented = false
    @FocusState private var searchFocused

    var body: some View {
        DataStateView(data: $viewModel.coursesForDashboard) {
            await viewModel.loadCourses()
        } content: { _ in
            ScrollView {
                if !viewModel.searchText.isEmpty || searchFocused {
                    GlobalSearchSection()
                        .padding(.m)
                        .background(.quinary, in: .rect(cornerRadius: .l))
                }

                if !viewModel.recentCourses.isEmpty && viewModel.searchText.isEmpty {
                    Text(R.string.localizable.recentlyAccessed())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.title.bold())
                        .padding(.top, searchFocused ? .m : 0)

                    LazyVGrid(columns: Self.layout, spacing: .l) {
                        ForEach(viewModel.recentCourses) { course in
                            CourseGridCell(courseForDashboard: course, viewModel: viewModel)
                                .matchedTransitionSource(id: course.id, in: namespace)
                        }
                    }

                    Text(R.string.localizable.allCourses())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.title.bold())
                        .padding(.top, .l)
                }
                LazyVGrid(columns: Self.layout, spacing: .l) {
                    ForEach(viewModel.filteredCourses) { course in
                        CourseGridCell(courseForDashboard: course, viewModel: viewModel)
                    }
                }
                if viewModel.filteredCourses.isEmpty && !viewModel.searchText.isEmpty && !globalSearchAvailable {
                    ContentUnavailableView.search
                }

                Button(R.string.localizable.dashboardRegisterForCourseButton()) {
                    isCourseRegistrationPresented = true
                }
                .buttonStyle(ArtemisButton())
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical)
            }
            .animation(.default, value: searchFocused)
            .contentMargins(.horizontal, .l, for: .scrollContent)
            .globalSearchable(searchText: $viewModel.searchText)
            .searchFocused($searchFocused)
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
    CourseGrid(namespace: Namespace().wrappedValue, viewModel: DashboardViewModel(courseService: CourseServiceStub()))
}
