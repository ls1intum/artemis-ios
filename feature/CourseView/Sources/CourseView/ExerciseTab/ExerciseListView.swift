import Foundation
import SwiftUI
import SharedModels
import Common
import DesignLibrary

struct ExerciseListView: View {

    @ObservedObject var viewModel: CourseViewModel

    private var weeklyExercises: [WeeklyExercise] {
        var groupedDates = [WeeklyExerciseId: [Exercise]]()

        viewModel.course.value?.exercises?.forEach { exercise in
            var week: Int? = nil
            var year: Int? = nil
            if let dueDate = exercise.baseExercise.dueDate {
                week = Calendar.current.component(.weekOfYear, from: dueDate)
                year = Calendar.current.component(.year, from: dueDate)
            }

            let weeklyExerciseId = WeeklyExerciseId(week: week, year: year)

            if groupedDates[weeklyExerciseId] == nil {
                groupedDates[weeklyExerciseId] = [exercise]
            } else {
                groupedDates[weeklyExerciseId]?.append(exercise)
            }
        }

        return groupedDates.map { week in
            WeeklyExercise(id: week.key, exercises: week.value)
        }.sorted(by: { $0.id.startOfWeek ?? .now < $1.id.startOfWeek ?? .now })
    }

    var body: some View {
        List {
            ForEach(weeklyExercises) { weeklyExercise in
                ExerciseListSection(weeklyExercise: weeklyExercise)
            }
        }.listStyle(PlainListStyle())
    }
}

struct ExerciseListSection: View {

    private let weeklyExercise: WeeklyExercise

    @State private var isExpanded: Bool

    fileprivate init(weeklyExercise: WeeklyExercise) {
        self.weeklyExercise = weeklyExercise

        var isExpanded = false
        if let exercise = self.weeklyExercise.exercises.first {
            isExpanded = Date.now <= exercise.baseExercise.dueDate ?? .now
        }
        _isExpanded = State(wrappedValue: isExpanded)
    }

    var body: some View {
        DisclosureGroup("\(weeklyExercise.id.description) (Exercises: \(weeklyExercise.exercises.count))",
                        isExpanded: $isExpanded) {
            ForEach(weeklyExercise.exercises) { exercise in
                ExerciseListCell(exercise: exercise)
            }.listRowInsets(EdgeInsets(top: .s, leading: 0, bottom: .s, trailing: .l))
        }.listRowSeparator(.hidden)
    }
}

struct ExerciseListCell: View {

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
                Text(exercise.baseExercise.title ?? "Unknown")
                    .font(.title3)
                Spacer()
            }
            if let dueDate = exercise.baseExercise.dueDate {
                Text("Due Date: \(dueDate.relative ?? "?")")
            } else {
                Text("No due date")
            }
            SubmissionResultStatusView(exercise: exercise)
            ScrollView(.horizontal) {
                LazyHGrid(rows: rows, spacing: .s) {
                    if let releaseDate = exercise.baseExercise.releaseDate,
                       releaseDate > .now {
                        Chip(text: "Not Released", backgroundColor: .red)
                    }
                    ForEach(exercise.baseExercise.categories ?? [], id: \.category) { category in
                        Chip(text: category.category, backgroundColor: UIColor(hexString: category.colorCode).suColor)
                    }
                    if let difficulty = exercise.baseExercise.difficulty {
                        Chip(text: difficulty.description, backgroundColor: .green)
                    }
                    if let includedInOverallScore = exercise.baseExercise.includedInOverallScore {
                        Chip(text: includedInOverallScore.description, backgroundColor: .blue)
                    }
                }
            }
        }
            .frame(maxWidth: .infinity)
            .padding(.l)
            .cardModifier(backgroundColor: Color.Artemis.exerciseCardBackgroundColor,
                          hasBorder: true,
                          borderColor: Color.Artemis.artemisBlue,
                          cornerRadius: 2)
    }
}

// struct ExerciseListView2: View {
//
//    let exerciseDataState: DataState<[WeeklyExercises]>
//    let onClickExercise: (_ exerciseId: Int) -> Void
//
//    @ObservedObject private var weeklyExercisesExpanded = WeeklyExercisesExpandedModel()
//
//    var body: some View {
//        EmptyDataStateView(dataState: exerciseDataState) { weeklyExercises in
//            ScrollView {
//                LazyVStack {
//                    ForEach(weeklyExercises) { (weeklyExercisesEntry: WeeklyExercises) in
//                        Section(header: ExerciseWeekSectionHeaderView(weeklyExercises: weeklyExercisesEntry)) {
//                            ForEach(weeklyExercisesEntry.exercises) { exercise in
//                                ExerciseItemView(exerciseWithParticipationStatus: exercise, onClick: {
//
//                                })
//                                .frame(maxWidth: .infinity)
//                                .padding(.horizontal, 8)
//                            }
//                        }
//                    }
//                }
//            }
//        }
//    }
//
//    private func areWeeklyExercisesExpanded(dict: [Date?: Bool], weeklyExercises: WeeklyExercises) -> Bool {
//        switch weeklyExercises {
//        case .BoundToWeek(firstDayOfWeek: let firstDayOfWeek, _, _):
//            let daysDiff = Calendar.current.dateComponents([.day], from: firstDayOfWeek, to: Date()).day ?? 0
//            let defaultValue = daysDiff < 14
//            return dict[firstDayOfWeek] ?? defaultValue
//        case .Unbound:
//            let defaultValue = true
//            return dict[nil] ?? defaultValue
//        }
//    }
// }
//
// private struct ExerciseWeekSectionHeaderView: View {
//    let weeklyExercises: WeeklyExercises
//
//    private let text: String
//
//    init(weeklyExercises: WeeklyExercises) {
//        self.weeklyExercises = weeklyExercises
//
//        switch weeklyExercises {
//        case .Unbound:
//            text = NSLocalizedString("course_ui_exercise_list_unbound_week_header", comment: "Section header for the exercises that are not bound to a week.")
//        case .BoundToWeek(firstDayOfWeek: let firstDayOfWeek, lastDayOfWeek: let lastDayOfWeek, _):
//            let dateFormatter = DateFormatter()
//            dateFormatter.dateStyle = .short
//            let fromText = dateFormatter.string(from: firstDayOfWeek)
//            let toText = dateFormatter.string(from: lastDayOfWeek)
//
//            let format = NSLocalizedString("course_ui_exercise_list_week_header", comment: "Display date range from week1 to week2")
//
//            text = String.localizedStringWithFormat(format, fromText, toText)
//        }
//
//    }
//
//    var body: some View {
//        Text(text)
//    }
// }
//
/// **
// * Display a single exercise.
// * The exercise is displayed in a card with an icon specific to the exercise type.
// */
// private struct ExerciseItemView: View {
//    let exerciseWithParticipationStatus: ExerciseWithParticipationStatus
//    let onClick: () -> Void
//
//    var body: some View {
//        let cardShape = RoundedRectangle(cornerRadius: 10, style: .continuous)
//
//        ZStack {
//            VStack(spacing: 8) {
//                HStack {
//                    ZStack {
//                        ExerciseTypeIconView(exercise: exerciseWithParticipationStatus.exercise)
//                            .frame(width: 60, height: 60)
//                            .padding([.leading, .top], 8)
//                    }
//                    .frame(width: 80, height: 80)
//
//                    ExerciseDataTextView(
//                        exercise: exerciseWithParticipationStatus.exercise,
//                        participationStatus: exerciseWithParticipationStatus.participationStatus
//                    )
//                    .frame(maxWidth: .infinity)
//                    .padding(.horizontal, 8)
//                }
//                .frame(maxWidth: .infinity)
//
//                // Display a row of chips
//                ScrollView(.horizontal) {
//                    HStack {
//                        ForEach(exerciseWithParticipationStatus.categoryChips) { chip in
//                            ExerciseCategoryChip(data: chip)
//                        }
//                    }
//                    .frame(maxWidth: .infinity)
//                    .padding(.horizontal, 8)
//                }
//                .frame(maxWidth: .infinity)
//            }
//            .frame(maxWidth: .infinity)
//            .padding(.vertical, 8)
//        }
//        .clipShape(cardShape)
//        .background(
//            cardShape
//                .stroke(Color.outline)
//        )
//        .background(
//            cardShape
//                .fill(Color.primaryContainer.surface)
//        )
//    }
// }
//
// private struct ExerciseTypeIconView: View {
//
//    let icon: String
//
//    init(exercise: Exercise) {
//        switch exercise {
//        case .FileUpload: icon = "square.and.arrow.up"
//        case .Modeling: icon = "compass.drawing"
//        case .Programming: icon = "terminal"
//        case .Quiz: icon = "questionmark.bubble"
//        case .Text: icon = "note.text"
//        case .Unknown: icon = "exclamationmark.triangle"
//        }
//    }
//
//    var body: some View {
//        Image(systemName: icon)
//            .resizable()
//            .scaledToFit()
//    }
// }
//
/// **
// * Displays the exercise title, the due data and the participation info. The participation info is automatically updated.
// */
// private struct ExerciseDataTextView: View {
//    let exercise: Exercise
//    let participationStatus: ParticipationStatus
//
//    let dueDateText: String
//
//    init(exercise: Exercise, participationStatus: ParticipationStatus) {
//        self.exercise = exercise
//        self.participationStatus = participationStatus
//
//        let formatter = RelativeDateTimeFormatter()
//
//        if let dueDate = exercise.baseExercise.dueDate {
//            let formattedDueDate = formatter.localizedString(for: dueDate, relativeTo: Date())
//            dueDateText = String.localizedStringWithFormat(NSLocalizedString("course_ui_exercise_item_due_date_set", comment: ""), formattedDueDate)
//        } else {
//            dueDateText = NSLocalizedString("course_ui_exercise_item_due_date_not_set", comment: "")
//        }
//    }
//
//    var body: some View {
//        VStack {
//            Text(verbatim: exercise.baseExercise.title ?? "")
//                .font(.title3)
//                .frame(maxWidth: .infinity, alignment: .leading)
//
//            Text(dueDateText)
//                .font(.callout)
//                .frame(maxWidth: .infinity, alignment: .leading)
//
//            switch participationStatus {
//            case .QuizFinished(participation: let p), .Initialized(participation: let p), .Inactive(participation: let p), .ExerciseSubmitted(participation: let p):
//                ExerciseResultView(
//                    exercise: exercise, participation: p, result: nil, showUngradedResults: true, personal: true
//                )
//                .frame(maxWidth: .infinity, alignment: .leading)
//            default:
//                Text(participationStatus.submissionResultStatusText)
//                    .font(.callout)
//                    .frame(maxWidth: .infinity, alignment: .leading)
//            }
//
//        }
//    }
// }
//
/// **
// * Displays a colored rounded rectangle with the given text in it.
// */
// private struct ExerciseCategoryChip: View {
//
//    let data: ExerciseCategoryChipData
//
//    var body: some View {
//        let chipShape = RoundedRectangle(cornerRadius: 25, style: .continuous)
//        ZStack {
//            ZStack {
//                switch data.text {
//                case .Verbatim(text: let text): Text(verbatim: text)
//                case .Localized(text: let text): Text(text)
//                }
//            }.padding(.all, 4)
//        }
//        .clipShape(chipShape)
//        .background(
//            chipShape.fill(data.color)
//        )
//    }
// }
//
// private extension ParticipationStatus {
//    var submissionResultStatusText: LocalizedStringKey {
//        switch self {
//        case .QuizNotInitialized: return "exercise_quiz_not_started"
//        case .QuizActive: return "exercise_user_participating"
//        case .QuizSubmitted: return "exercise_user_submitted"
//        case .QuizNotStarted: return "exercise_quiz_not_started"
//        case .QuizNotParticipated: return "exercise_user_not_participated"
//        case .NoTeamAssigned: return "exercise_user_not_assigned_to_team"
//        case .Uninitialized: return "exercise_user_not_started_exercise"
//        case .ExerciseActive: return "exercise_exercise_not_submitted"
//        case .ExerciseMissed: return "exercise_exercise_missed_deadline"
//        default: return ""
//        }
//    }
// }

private struct WeeklyExerciseId: Identifiable, Hashable {
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

private struct WeeklyExercise: Identifiable {
    let id: WeeklyExerciseId
    var exercises: [Exercise]
}
