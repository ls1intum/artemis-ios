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
    @ObservedObject var viewModel: CourseViewModel

    @Binding var searchText: String

    var body: some View {
        ScrollViewReader { value in
            List {
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
            .listStyle(.plain)
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
            LazyVStack(spacing: .m) {
                ForEach(weeklyLecture.lectures, id: \.id) { lecture in
                    LectureListCellView(course: course, lecture: lecture)
                }
            }
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: .l))
        }
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: .m, leading: .l, bottom: .m, trailing: .l))
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
        VStack(alignment: .leading, spacing: .m) {
            HStack(spacing: .l) {
                lecture.image
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(Color.Artemis.primaryLabel)
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
        .padding(.l)
        .cardModifier(backgroundColor: .Artemis.exerciseCardBackgroundColor, cornerRadius: .m)
        .onTapGesture {
            navigationController.path.append(LecturePath(lecture: lecture, coursePath: CoursePath(course: course)))
        }
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
