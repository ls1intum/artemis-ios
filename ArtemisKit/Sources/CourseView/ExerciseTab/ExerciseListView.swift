import Foundation
import SwiftUI
import SharedModels
import Common
import Navigation
import DesignLibrary

struct ExerciseListView: View {
    @ObservedObject var viewModel: CourseViewModel

    @Binding var searchText: String

    var body: some View {
        ScrollViewReader { value in
            List {
                if searchText.isEmpty {
                    ForEach(weeklyExercises) { weeklyExercise in
                        if let course = viewModel.course.value {
                            ExerciseListSection(course: course, weeklyExercise: weeklyExercise)
                                .id(weeklyExercise.id)
                        }
                    }
                } else {
                    if searchResults.isEmpty {
                        ContentUnavailableView.search(text: searchText)
                            .listRowSeparator(.hidden)
                    } else {
                        ForEach(searchResults) { exercise in
                            if let course = viewModel.course.value {
                                ExerciseListCell(course: course, exercise: exercise)
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .onChange(of: weeklyExercises) { _, newValue in
                withAnimation {
                    if let id = newValue.first(where: { $0.exercises.first?.baseExercise.dueDate ?? .tomorrow > .now })?.id {
                        value.scrollTo(id, anchor: .top)
                    }
                }
            }
        }
        .refreshable {
            if let courseId = viewModel.course.value?.id {
                await viewModel.loadCourse(id: courseId)
            }
        }
    }
}

private extension ExerciseListView {
    var searchResults: [Exercise] {
        guard let course = viewModel.course.value,
              let exercises = course.exercises else {
            return []
        }
        return exercises.filter { exercise in
            let range = exercise.baseExercise.title?.range(of: searchText, options: [.caseInsensitive, .diacriticInsensitive])
            return range != nil
        }
    }

    var weeklyExercises: [WeeklyExercise] {
        guard let course = viewModel.course.value,
              let exercises = course.exercises else {
            return []
        }
        let groupedDates = exercises.reduce(into: [WeeklyExerciseId: [Exercise]]()) { partialResult, exercise in
            var week: Int?
            var year: Int?
            if let dueDate = exercise.baseExercise.dueDate {
                week = Calendar.current.component(.weekOfYear, from: dueDate)
                year = Calendar.current.component(.year, from: dueDate)
            }

            let weeklyExerciseId = WeeklyExerciseId(week: week, year: year)

            if partialResult[weeklyExerciseId] == nil {
                partialResult[weeklyExerciseId] = [exercise]
            } else {
                partialResult[weeklyExerciseId]?.append(exercise)
            }
        }
        let weeklyExercises = groupedDates.map { week in
            let exercises = week.value.sorted {
                let lhs = $0.baseExercise.title?.lowercased() ?? ""
                let rhs = $1.baseExercise.title?.lowercased() ?? ""
                return lhs.compare(rhs) == .orderedAscending
            }
            return WeeklyExercise(id: week.key, exercises: exercises)
        }
        return weeklyExercises.sorted {
            let lhs = $0.id.startOfWeek ?? .distantFuture
            let rhs = $1.id.startOfWeek ?? .distantFuture
            return lhs.compare(rhs) == .orderedAscending
        }
    }
}

struct ExerciseListSection: View {

    private let course: Course
    private let weeklyExercise: WeeklyExercise

    @State private var isExpanded: Bool

    fileprivate init(course: Course, weeklyExercise: WeeklyExercise) {
        self.course = course
        self.weeklyExercise = weeklyExercise

        var isExpanded = false
        if let exercise = self.weeklyExercise.exercises.first {
            isExpanded = Date.now <= exercise.baseExercise.dueDate ?? .now
        }
        _isExpanded = State(wrappedValue: isExpanded)
    }

    var body: some View {
        DisclosureGroup(
            "\(weeklyExercise.id.description) (Exercises: \(weeklyExercise.exercises.count))",
            isExpanded: $isExpanded
        ) {
            LazyVStack(spacing: .m) {
                ForEach(weeklyExercise.exercises) { exercise in
                    ExerciseListCell(course: course, exercise: exercise)
                }
            }
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: .l))
        }
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: .m, leading: .l, bottom: .m, trailing: .l))
    }
}

struct ExerciseListCell: View {
    @EnvironmentObject var navigationController: NavigationController

    let course: Course
    let exercise: Exercise

    let rows = [
        GridItem()
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: .m) {
            HStack(spacing: .l) {
                exercise.image
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(Color.Artemis.primaryLabel)
                    .frame(width: .smallImage)
                Text(exercise.baseExercise.title ?? "")
                    .font(.title3)
                Spacer()
            }
            if let dueDate = exercise.baseExercise.dueDate {
                Text(R.string.localizable.dueDate(dueDate.relative ?? "?"))
            } else {
                Text(R.string.localizable.noDueDate())
            }
            SubmissionResultStatusView(exercise: exercise)
            ScrollView(.horizontal) {
                LazyHGrid(rows: rows, spacing: .s) {
                    if let releaseDate = exercise.baseExercise.releaseDate,
                       releaseDate > .now {
                        Chip(
                            text: R.string.localizable.notReleased(),
                            backgroundColor: Color.Artemis.badgeWarningColor)
                    }
                    ForEach(exercise.baseExercise.categories ?? [], id: \.category) { category in
                        Chip(text: category.category, backgroundColor: UIColor(hexString: category.colorCode).suColor)
                    }
                    // TODO: maybe add isActiveQuiz in presentationMode badge
                    if let difficulty = exercise.baseExercise.difficulty {
                        Chip(text: difficulty.description, backgroundColor: difficulty.color)
                    }
                    if exercise.baseExercise.includedInOverallScore != .includedCompletly {
                        Chip(
                            text: exercise.baseExercise.includedInOverallScore.description,
                            backgroundColor: exercise.baseExercise.includedInOverallScore.color)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.l)
        .artemisStyleCard()
        .onTapGesture {
            navigationController.append(ExercisePath(exercise: exercise, coursePath: CoursePath(course: course)))
        }
    }
}

private struct WeeklyExerciseId: Identifiable, Hashable {
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
            return "No date associated"
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

private struct WeeklyExercise: Identifiable, Hashable {
    let id: WeeklyExerciseId
    var exercises: [Exercise]
}
