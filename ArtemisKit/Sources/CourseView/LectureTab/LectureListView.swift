//
//  LectureListView.swift
//  
//
//  Created by Sven Andabaka on 27.04.23.
//

import DesignLibrary
import Navigation
import Notifications
import SharedModels
import SwiftUI
import Messages

struct LectureListView: View {
    @EnvironmentObject var navController: NavigationController
    @ObservedObject var viewModel: CourseViewModel
    @State private var columnVisibilty: NavigationSplitViewVisibility = .doubleColumn

    @State private var searchText = ""

    private var selectedLecture: Binding<LecturePath?> {
        navController.selectedPathBinding($navController.selectedPath)
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibilty) {
            ScrollViewReader { value in
                List(selection: selectedLecture) {
                    if searchText.isEmpty {
                        if lectureGroups.isEmpty {
                            ContentUnavailableView(R.string.localizable.lecturesUnavailable(), systemImage: "character.book.closed")
                                .listRowSeparator(.hidden)
                        } else {
                            ForEach(lectureGroups) { lectureGroup in
                                LectureListSectionView(course: viewModel.course, lectureGroup: lectureGroup)
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
                .searchable(text: $searchText)
                .refreshable {
                    await viewModel.refreshCourse()
                }
                .onChange(of: lectureGroups) { _, newValue in
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
            .courseToolbar()
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
                        SelectDetailView()
                    }
                }
                .modifier(NavigationDestinationMessagesModifier())
                .navigationDestination(for: LecturePath.self) { lecturePath in
                    if let course = lecturePath.coursePath.course {
                        LectureDetailView(course: course, lectureId: lecturePath.id)
                    } else {
                        LectureDetailView(courseId: lecturePath.coursePath.id, lectureId: lecturePath.id)
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

    var lectureGroups: [LectureGroup] {
        guard let lectures = viewModel.course.lectures else {
            return []
        }

        let groupedDates = lectures.reduce(into: [LectureGroup.GroupType: [Lecture]]()) { partialResult, lecture in
            let start = lecture.startDate
            let end = lecture.endDate
            let type: LectureGroup.GroupType

            if start == nil || start ?? .now < .now {
                if end == nil {
                    type = .noDate
                } else if end ?? .now < .now {
                    type = .past
                } else {
                    type = .current
                }
            } else {
                type = .future
            }

            if partialResult[type] == nil {
                partialResult[type] = [lecture]
            } else {
                partialResult[type]?.append(lecture)
            }
        }

        let groups = groupedDates.map { group in
            let lectures = group.value.sorted {
                if let lhsDue = $0.endDate,
                   let rhsDue = $1.endDate {
                    return lhsDue.compare(rhsDue) == .orderedAscending
                }
                let lhs = $0.title?.lowercased() ?? ""
                let rhs = $1.title?.lowercased() ?? ""
                return lhs.compare(rhs) == .orderedAscending
            }
            return LectureGroup(type: group.key, lectures: lectures)
        }
        return groups.sorted(by: <)
    }
}

private struct LectureListSectionView: View {
    private let course: Course
    private let lectureGroup: LectureGroup

    @State private var isExpanded: Bool

    init(course: Course, lectureGroup: LectureGroup) {
        self.course = course
        self.lectureGroup = lectureGroup

        let isCurrent = lectureGroup.type == .current
        _isExpanded = State(wrappedValue: isCurrent)
    }

    var body: some View {
        DisclosureGroup(
            "\(lectureGroup.type.description) (^[\(lectureGroup.lectures.count) \(R.string.localizable.lecture())](inflect:true))",
            isExpanded: $isExpanded
        ) {
            ForEach(lectureGroup.weeklyLectures, id: \.id) { weeklyLecture in
                /// If more than 5 lectures, group by week as well
                if lectureGroup.type != .noDate && lectureGroup.lectures.count > 5 {
                    Section(weeklyLecture.id.description) {
                        WeeklyLectureView(weeklyLecture: weeklyLecture, course: course)
                    }
                } else {
                    WeeklyLectureView(weeklyLecture: weeklyLecture, course: course)
                }
            }
        }
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: .s))
        .listRowBackground(Color.clear)
    }
}

struct WeeklyLectureView: View {
    fileprivate let weeklyLecture: WeeklyLecture
    let course: Course

    var body: some View {
        ForEach(weeklyLecture.lectures) { lecture in
            LectureListCellView(course: course, lecture: lecture)
        }
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
            .padding(.horizontal, .m)
            .padding(.vertical, .l)
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

private struct LectureGroup: Identifiable, Hashable, Comparable {
    static func < (lhs: LectureGroup, rhs: LectureGroup) -> Bool {
        lhs.type < rhs.type
    }

    var id: Int {
        type.hashValue
    }

    let type: GroupType
    var lectures: [Lecture]

    var weeklyLectures: [WeeklyLecture] {
        let groupedDates = lectures.reduce(into: [WeeklyLectureId: [Lecture]]()) { partialResult, lecture in
            var week: Int?
            var year: Int?
            if let dueDate = lecture.endDate {
                week = Calendar.current.component(.weekOfYear, from: dueDate)
                year = Calendar.current.component(.year, from: dueDate)
            }

            let weeklyLectureId = WeeklyLectureId(week: week, year: year)

            if partialResult[weeklyLectureId] == nil {
                partialResult[weeklyLectureId] = [lecture]
            } else {
                partialResult[weeklyLectureId]?.append(lecture)
            }
        }
        let weeklyLectures = groupedDates.map { week in
            WeeklyLecture(id: week.key, lectures: week.value)
        }
        return weeklyLectures.sorted {
            let lhs = $0.id.startOfWeek ?? .distantFuture
            let rhs = $1.id.startOfWeek ?? .distantFuture
            return lhs.compare(rhs) == .orderedAscending
        }
    }

    enum GroupType: Hashable, Comparable {
        case past, current, future, noDate

        var description: String {
            return switch self {
            case .noDate:
                R.string.localizable.noDateAssociated()
            case .past:
                R.string.localizable.past()
            case .current:
                R.string.localizable.current()
            case .future:
                R.string.localizable.future()
            }
        }
    }
}
