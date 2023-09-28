//
//  LectureListView.swift
//  
//
//  Created by Sven Andabaka on 27.04.23.
//

import SwiftUI
import SharedModels
import Navigation
import DesignLibrary

struct LectureListView: View {

    @ObservedObject var viewModel: CourseViewModel

    @Binding var searchText: String

    private var searchResults: [Lecture] {
        if searchText.isEmpty {
            return []
        }
        return (viewModel.course.value?.lectures ?? []).filter { ($0.title ?? "").lowercased().contains(searchText.lowercased()) }
    }

    private var weeklyLectures: [WeeklyLecture] {
        var groupedDates = [WeeklyLectureId: [Lecture]]()

        viewModel.course.value?.lectures?.forEach { lecture in
            var week: Int?
            var year: Int?
            if let dueDate = lecture.startDate {
                week = Calendar.current.component(.weekOfYear, from: dueDate)
                year = Calendar.current.component(.year, from: dueDate)
            }

            let weeklyLectureId = WeeklyLectureId(week: week, year: year)

            if groupedDates[weeklyLectureId] == nil {
                groupedDates[weeklyLectureId] = [lecture]
            } else {
                groupedDates[weeklyLectureId]?.append(lecture)
            }
        }

        let weeklyLectures = groupedDates
            .map { week in
                let lectures = week.value.sorted(by: {
                    $0.title?.lowercased() ?? "" < $1.title?.lowercased() ?? ""
                })
                return WeeklyLecture(id: week.key, lectures: lectures)
            }
            .sorted(by: {
                $0.id.startOfWeek ?? .distantFuture < $1.id.startOfWeek ?? .distantFuture
            })
        return weeklyLectures
    }

    var body: some View {
        ScrollViewReader { value in
            List {
                if searchText.isEmpty {
                    ForEach(weeklyLectures) { weeklyLecture in
                        if let course = viewModel.course.value {
                            LectureListSection(course: course, weeklyLecture: weeklyLecture)
                        }
                    }
                } else {
                    if searchResults.isEmpty {
                        Text("There is no result for your search.")
                            .padding(.l)
                            .listRowSeparator(.hidden)
                    } else {
                        ForEach(searchResults) { lecture in
                            if let course = viewModel.course.value {
                                LectureListCell(course: course, lecture: lecture)
                            }
                        }
                    }
                }
            }
                .listStyle(PlainListStyle())
                .onChange(of: weeklyLectures) { newValue in
                    withAnimation {
                        if let id = newValue.first(where: { $0.lectures.first?.startDate ?? .tomorrow > .now })?.id {
                            value.scrollTo(id, anchor: .top)
                        }
                    }
                }
        }
    }
}

struct LectureListSection: View {

    private let course: Course
    private let weeklyLecture: WeeklyLecture

    @State private var isExpanded: Bool

    fileprivate init(course: Course, weeklyLecture: WeeklyLecture) {
        self.course = course
        self.weeklyLecture = weeklyLecture

        var isExpanded = false
        if let lecture = self.weeklyLecture.lectures.first {
            isExpanded = Date.now <= lecture.startDate ?? .now
        }
        _isExpanded = State(wrappedValue: isExpanded)
    }

    var body: some View {
        DisclosureGroup("\(weeklyLecture.id.description) (Exercises: \(weeklyLecture.lectures.count))",
                        isExpanded: $isExpanded) {
            LazyVStack(spacing: .m) {
                ForEach(weeklyLecture.lectures, id: \.id) { lecture in
                    LectureListCell(course: course, lecture: lecture)
                }
            }.listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: .l))
        }
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: .m, leading: .l, bottom: .m, trailing: .l))
    }
}

struct LectureListCell: View {

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
                Text("No due date")
            }
        }
            .frame(maxWidth: .infinity)
            .padding(.l)
            .cardModifier(backgroundColor: Color.Artemis.exerciseCardBackgroundColor,
                          hasBorder: true,
                          borderColor: Color.Artemis.artemisBlue,
                          cornerRadius: 2)
            .onTapGesture {
                navigationController.path.append(LecturePath(lecture: lecture, coursePath: CoursePath(course: course)))
            }
    }
}

private struct WeeklyLectureId: Identifiable, Hashable {
    let week: Int?
    let year: Int?

    var id: String {
        guard let week,
              let year else {
            return "undefined"
        }
        return "\(week)/\(year)"
    }

    var description: String {
        guard let startOfWeek, let endOfWeek else { return "No date associated" }
        return "\(startOfWeek.dateOnly) - \(endOfWeek.dateOnly)"
    }

    var startOfWeek: Date? {
        guard let week, let year else { return nil }

        var dateComponents = DateComponents()
        dateComponents.yearForWeekOfYear = year
        dateComponents.weekOfYear = week
        dateComponents.weekday = Calendar.current.firstWeekday
        return Calendar.current.date(from: dateComponents)
    }

    var endOfWeek: Date? {
        guard let startOfWeek else { return nil }
        return Calendar.current.date(byAdding: .day, value: 6, to: startOfWeek)
    }
}

private struct WeeklyLecture: Identifiable, Hashable {
    let id: WeeklyLectureId
    var lectures: [Lecture]
}
