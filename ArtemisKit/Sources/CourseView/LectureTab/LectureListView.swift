//
//  LectureListView.swift
//  
//
//  Created by Sven Andabaka on 27.04.23.
//

import DesignLibrary
import Navigation
import SharedModels
import SwiftUI

struct LectureListView: View {
    @EnvironmentObject var navController: NavigationController
    @ObservedObject var viewModel: CourseViewModel
    @State private var columnVisibilty: NavigationSplitViewVisibility = .doubleColumn

    @Binding var searchText: String

    private var selectedLecture: Binding<LecturePath?> {
        navController.selectedPathBinding($navController.selectedPath)
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibilty) {
            ScrollViewReader { value in
                List(selection: selectedLecture) {
                    if searchText.isEmpty {
                        if weeklyLectures.isEmpty {
                            ContentUnavailableView(R.string.localizable.lecturesUnavailable(), systemImage: "character.book.closed")
                                .listRowSeparator(.hidden)
                        } else {
                            ForEach(weeklyLectures) { weeklyLecture in
                                LectureListSectionView(course: viewModel.course, weeklyLecture: weeklyLecture)
                            }
                        }
                    } else {
                        if searchResults.isEmpty {
                            ContentUnavailableView.search(text: searchText)
                                .listRowSeparator(.hidden)
                        } else {
                            ForEach(searchResults) { lecture in
                                LectureListCellView(course: viewModel.course, lecture: lecture)
                            }
                        }
                    }
                }
                .listRowSpacing(.m)
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .refreshable {
                    await viewModel.refreshCourse()
                }
                .onChange(of: weeklyLectures) { _, newValue in
                    withAnimation {
                        let lecture = newValue.first {
                            $0.lectures.first?.startDate ?? .tomorrow > .now
                        }
                        if let id = lecture?.id {
                            value.scrollTo(id, anchor: .top)
                        }
                    }
                }
            }
            .navigationTitle(viewModel.course.title ?? R.string.localizable.loading())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        navController.popToRoot()
                    } label: {
                        HStack(spacing: .s) {
                            Image(systemName: "chevron.backward")
                                .fontWeight(.semibold)
                            Text("Back")
                        }
                        .offset(x: -8)
                    }
                }
            }
        } detail: {
            NavigationStack(path: $navController.tabPath) {
                Group {
                    if let path = navController.selectedPath as? LecturePath {
                        Group {
                            if let course = path.coursePath.course {
                                LectureDetailView(course: course, lectureId: path.id)
                            } else {
                                LectureDetailView(courseId: path.coursePath.id, lectureId: path.id)
                            }
                        }
                        .id(path.id)
                    } else {
                        #warning("TODO: Localize")
                        Text("Select a Lecture")
                    }
                }
                .navigationDestination(for: LecturePath.self) { lecturePath in
                    if let course = lecturePath.coursePath.course {
                        LectureDetailView(course: course, lectureId: lecturePath.id)
                    } else {
                        LectureDetailView(courseId: lecturePath.coursePath.id, lectureId: lecturePath.id)
                    }
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

private extension LectureListView {
    var searchResults: [Lecture] {
        guard let lectures = viewModel.course.lectures else {
            return []
        }
        return lectures.filter { lecture in
            let range = lecture.title?.range(of: searchText, options: [.caseInsensitive, .diacriticInsensitive])
            return range != nil
        }
    }

    var weeklyLectures: [WeeklyLecture] {
        guard let lectures = viewModel.course.lectures else {
            return []
        }
        let groupedDates = Dictionary(grouping: lectures) { lecture in
            var week: Int?
            var year: Int?
            if let dueDate = lecture.startDate {
                week = Calendar.current.component(.weekOfYear, from: dueDate)
                year = Calendar.current.component(.year, from: dueDate)
            }
            return WeeklyLectureId(week: week, year: year)
        }
        let weeklyLectures = groupedDates
            .map { week in
                let lectures = week.value.sorted {
                    let lhs = $0.startDate ?? .now
                    let rhs = $1.startDate ?? .now
                    return lhs.compare(rhs) == .orderedAscending
                }
                return WeeklyLecture(id: week.key, lectures: lectures)
            }
            .sorted {
                let lhs = $0.id.startOfWeek ?? .distantFuture
                let rhs = $1.id.startOfWeek ?? .distantFuture
                return lhs.compare(rhs) == .orderedAscending
            }
        return weeklyLectures
    }
}

private struct LectureListSectionView: View {
    private let course: Course
    private let weeklyLecture: WeeklyLecture

    @State private var isExpanded: Bool

    init(course: Course, weeklyLecture: WeeklyLecture) {
        self.course = course
        self.weeklyLecture = weeklyLecture

        var isExpanded = false
        if let lecture = self.weeklyLecture.lectures.first {
            isExpanded = Date.now <= lecture.startDate ?? .now
        }
        _isExpanded = State(wrappedValue: isExpanded)
    }

    var body: some View {
        DisclosureGroup(
            R.string.localizable.lecturesGroupTitle(weeklyLecture.id.description, weeklyLecture.lectures.count),
            isExpanded: $isExpanded
        ) {
            ForEach(weeklyLecture.lectures, id: \.id) { lecture in
                LectureListCellView(course: course, lecture: lecture)
            }
        }
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets())
    }
}

private struct LectureListCellView: View {
    @EnvironmentObject var navigationController: NavigationController

    let course: Course
    let lecture: Lecture

    let rows = [
        GridItem()
    ]

    var body: some View {
        NavigationLink(value: LecturePath(lecture: lecture, coursePath: CoursePath(course: course))) {
            VStack(alignment: .leading, spacing: .m) {
                HStack(spacing: .l) {
                    lecture.image
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: .smallImage)
                    Text(lecture.title ?? "Unknown")
                        .font(.title3)
                    Spacer()
                }
                if let startDate = lecture.startDate {
                    Text("\(startDate.dateOnly) (\(startDate.relative ?? "?"))")
                } else {
                    Text(R.string.localizable.noDateAssociated())
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.m)
        }
        .foregroundColor(Color.Artemis.primaryLabel)
        .listRowInsets(EdgeInsets(top: 0, leading: .m * -1, bottom: 0, trailing: .m * -1))
        .listRowBackground(Color.Artemis.exerciseCardBackgroundColor)
        .tag(LecturePath(lecture: lecture, coursePath: CoursePath(course: course)))
    }
}

// MARK: - WeeklyLecture

private struct WeeklyLecture: Identifiable, Hashable {
    let id: WeeklyLectureId
    var lectures: [Lecture]
}

private struct WeeklyLectureId: Hashable, Identifiable {
    let week: Int?
    let year: Int?

    var id: String {
        guard let week, let year else {
            return "undefined"
        }
        return "\(week)/\(year)"
    }

    var description: String {
        guard let startOfWeek, let endOfWeek else {
            return R.string.localizable.noDateAssociated()
        }
        return "\(startOfWeek.dateOnly) - \(endOfWeek.dateOnly)"
    }

    var startOfWeek: Date? {
        guard let week, let year else {
            return nil
        }

        var dateComponents = DateComponents()
        dateComponents.yearForWeekOfYear = year
        dateComponents.weekOfYear = week
        dateComponents.weekday = Calendar.current.firstWeekday
        return Calendar.current.date(from: dateComponents)
    }

    var endOfWeek: Date? {
        guard let startOfWeek else {
            return nil
        }
        return Calendar.current.date(byAdding: .day, value: 6, to: startOfWeek)
    }
}
