import Foundation
import Messages
import SwiftUI
import SharedModels
import Common
import Navigation
import Notifications
import DesignLibrary

struct ExerciseListView: View {
    @EnvironmentObject var navController: NavigationController
    @Environment(\.horizontalSizeClass) var sizeClass
    @ObservedObject var viewModel: CourseViewModel
    @State private var columnVisibilty: NavigationSplitViewVisibility = .doubleColumn

    @State private var searchText = ""

    private var selectedExercise: Binding<ExercisePath?> {
        navController.selectedPathBinding($navController.selectedPath)
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibilty) {
            ScrollViewReader { value in
                List(selection: selectedExercise) {
                    if searchText.isEmpty {
                        if exerciseGroups.isEmpty {
                            ContentUnavailableView(R.string.localizable.exercisesUnavailable(), systemImage: "list.bullet.clipboard")
                                .listRowSeparator(.hidden)
                        } else {
                            ForEach(exerciseGroups) { exerciseGroup in
                                ExerciseListSection(course: viewModel.course, exerciseGroup: exerciseGroup)
                                    .id(exerciseGroup.id)
                            }
                        }
                    } else {
                        if searchResults.isEmpty {
                            ContentUnavailableView.search(text: searchText)
                                .listRowSeparator(.hidden)
                        } else {
                            ForEach(searchResults) { exercise in
                                ExerciseListCell(course: viewModel.course, exercise: exercise)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .listSectionSpacing(.compact)
                .scrollContentBackground(.hidden)
                .listRowSpacing(.m)
                .searchable(text: $searchText)
                .refreshable {
                    await viewModel.refreshCourse()
                }
                .onChange(of: exerciseGroups) { _, newValue in
                    withAnimation {
                        if let id = newValue.first(where: { $0.exercises.first?.baseExercise.dueDate ?? .tomorrow > .now })?.id {
                            value.scrollTo(id, anchor: .top)
                        }
                    }
                }
            }
            .navigationTitle(viewModel.course.title ?? R.string.localizable.loading())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    BackToRootButton(placement: .navBar, sizeClass: sizeClass)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    CourseNotificationToolbarButton(placement: .navBar, sizeClass: sizeClass)
                }
            }
        } detail: {
            NavigationStack(path: $navController.tabPath) {
                Group {
                    if let path = navController.selectedPath as? ExercisePath {
                        Group {
                            if let course = path.coursePath.course,
                               let exercise = path.exercise {
                                ExerciseDetailView(course: course, exercise: exercise)
                            } else {
                                ExerciseDetailView(courseId: path.coursePath.id, exerciseId: path.id)
                            }
                        }
                        .id(path.id)
                    } else {
                        SelectDetailView()
                    }
                }
                .modifier(NavigationDestinationMessagesModifier())
                .navigationDestination(for: ExercisePath.self) { exercisePath in
                    if let course = exercisePath.coursePath.course,
                       let exercise = exercisePath.exercise {
                        ExerciseDetailView(course: course, exercise: exercise)
                    } else {
                        ExerciseDetailView(courseId: exercisePath.coursePath.id, exerciseId: exercisePath.id)
                    }
                }
            }
        }
    }
}

private extension ExerciseListView {
    var searchResults: [Exercise] {
        guard let exercises = viewModel.course.exercises else {
            return []
        }
        return exercises.filter { exercise in
            let range = exercise.baseExercise.title?.range(of: searchText, options: [.caseInsensitive, .diacriticInsensitive])
            return range != nil
        }
    }

    var exerciseGroups: [ExerciseGroup] {
        guard let exercises = viewModel.course.exercises else {
            return []
        }

        let groupedDates = exercises.reduce(into: [ExerciseGroup.GroupType: [Exercise]]()) { partialResult, exercise in
            let start = exercise.baseExercise.releaseDate
            let end = exercise.baseExercise.dueDate
            let type: ExerciseGroup.GroupType

            if start == nil || start ?? .now < .now {
                if end == nil {
                    type = .noDate
                } else if end ?? .now < .now {
                    type = .past
                } else if end?.distance(to: .now) ?? 0 > 3 * 24 * 60 * 60 {
                    type = .dueSoon
                } else {
                    type = .current
                }
            } else {
                type = .future
            }

            if partialResult[type] == nil {
                partialResult[type] = [exercise]
            } else {
                partialResult[type]?.append(exercise)
            }
        }

        let groups = groupedDates.map { group in
            let exercises = group.value.sorted {
                if let lhsDue = $0.baseExercise.dueDate,
                   let rhsDue = $1.baseExercise.dueDate {
                    return lhsDue.compare(rhsDue) == .orderedAscending
                }
                let lhs = $0.baseExercise.title?.lowercased() ?? ""
                let rhs = $1.baseExercise.title?.lowercased() ?? ""
                return lhs.compare(rhs) == .orderedAscending
            }
            return ExerciseGroup(type: group.key, exercises: exercises)
        }
        return groups.sorted(by: <)
    }
}

struct ExerciseListSection: View {

    private let course: Course
    private let exerciseGroup: ExerciseGroup

    @State private var isExpanded: Bool

    fileprivate init(course: Course, exerciseGroup: ExerciseGroup) {
        self.course = course
        self.exerciseGroup = exerciseGroup

        let isCurrentOrDue = exerciseGroup.type == .current || exerciseGroup.type == .dueSoon
        _isExpanded = State(wrappedValue: isCurrentOrDue)
    }

    var body: some View {
        DisclosureGroup(
            "\(exerciseGroup.type.description) (^[\(exerciseGroup.exercises.count) \(R.string.localizable.exercise())](inflect:true))",
            isExpanded: $isExpanded
        ) {
            ForEach(exerciseGroup.weeklyExercises) { exercise in
                /// If more than 5 exercises, group by week as well
                if exerciseGroup.type != .noDate && exerciseGroup.exercises.count > 5 {
                    Section(exercise.id.description) {
                        WeeklyExerciseView(weeklyExercise: exercise, course: course)
                    }
                } else {
                    WeeklyExerciseView(weeklyExercise: exercise, course: course)
                }
            }
        }
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: .m, leading: 0, bottom: .m, trailing: .s))
        .listRowBackground(Color.clear)
        .listSectionSpacing(.compact)
    }
}

struct WeeklyExerciseView: View {
    fileprivate let weeklyExercise: WeeklyExercise
    let course: Course

    var body: some View {
        ForEach(weeklyExercise.exercises) { exercise in
            ExerciseListCell(course: course, exercise: exercise)
        }
    }
}

struct ExerciseListCell: View {
    @EnvironmentObject var navigationController: NavigationController

    let course: Course
    let exercise: Exercise

    var showAdditionalBadges: Bool {
        if let releaseDate = exercise.baseExercise.releaseDate,
           releaseDate > .now {
            return true
        }
        if let categories = exercise.baseExercise.categories, !categories.isEmpty {
            return true
        }
        return exercise.baseExercise.includedInOverallScore != .includedCompletely
    }

    var body: some View {
        NavigationLink(value: ExercisePath(exercise: exercise, coursePath: CoursePath(course: course))) {
            HStack(alignment: .top, spacing: 0) {
                if let difficulty = exercise.baseExercise.difficulty {
                    Rectangle()
                        .frame(width: .m)
                        .foregroundStyle(difficulty.color)
                        .accessibilityLabel(difficulty.description)
                }
                VStack(alignment: .leading, spacing: .m) {
                    HStack(spacing: .m) {
                        exercise.image
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: .smallImage)
                        Text(exercise.baseExercise.title ?? "")
                            .font(.title3)
                            .lineLimit(1)
                    }
                    if let dueDate = exercise.baseExercise.dueDate {
                        Text(dueDate, style: .date)
                    } else {
                        Text(R.string.localizable.noDueDate())
                    }
                    SubmissionResultStatusView(exercise: exercise)
                    if showAdditionalBadges {
                        ScrollView(.horizontal) {
                            HStack(spacing: .s) {
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
                                if exercise.baseExercise.includedInOverallScore != .includedCompletely {
                                    Chip(
                                        text: exercise.baseExercise.includedInOverallScore.description,
                                        backgroundColor: exercise.baseExercise.includedInOverallScore.color)
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.l)
            }
            .foregroundColor(Color.Artemis.primaryLabel)
        }
        .tag(ExercisePath(exercise: exercise, coursePath: CoursePath(course: course)))
        .listRowInsets(EdgeInsets(top: 0, leading: -20, bottom: 0, trailing: .m * -1))
        .listRowBackground(Color.Artemis.exerciseCardBackgroundColor)
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

private struct ExerciseGroup: Identifiable, Hashable, Comparable {
    static func < (lhs: ExerciseGroup, rhs: ExerciseGroup) -> Bool {
        lhs.type < rhs.type
    }

    var id: Int {
        type.hashValue
    }

    let type: GroupType
    var exercises: [Exercise]

    var weeklyExercises: [WeeklyExercise] {
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
            WeeklyExercise(id: week.key, exercises: week.value)
        }
        return weeklyExercises.sorted {
            let lhs = $0.id.startOfWeek ?? .distantFuture
            let rhs = $1.id.startOfWeek ?? .distantFuture
            return lhs.compare(rhs) == .orderedAscending
        }
    }

    enum GroupType: Hashable, Comparable {
        case past, dueSoon, current, future, noDate

        var description: String {
            return switch self {
            case .noDate:
                R.string.localizable.noDateAssociated()
            case .past:
                R.string.localizable.past()
            case .current:
                R.string.localizable.current()
            case .dueSoon:
                R.string.localizable.dueSoon()
            case .future:
                R.string.localizable.future()
            }
        }
    }
}
