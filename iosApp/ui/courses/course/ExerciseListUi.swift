import Foundation
import SwiftUI
import SwiftDate
import Model

private class WeeklyExercisesExpandedModel: ObservableObject {

    /**
     * Map from the firstDayOfTheWeek
     */
    @Published var isExpanded: [Date?: Bool] = [:]
}

struct ExerciseListView: View {

    let exerciseDataState: DataState<[WeeklyExercises]>
    let onClickExercise: (_ exerciseId: Int) -> Void

    @ObservedObject private var weeklyExercisesExpanded = WeeklyExercisesExpandedModel()

    var body: some View {
        EmptyDataStateView(dataState: exerciseDataState) { weeklyExercises in
            ScrollView {
                LazyVStack {
                    ForEach(weeklyExercises) { (weeklyExercisesEntry: WeeklyExercises) in
                        Section(header: ExerciseWeekSectionHeaderView(weeklyExercises: weeklyExercisesEntry)) {
                            ForEach(weeklyExercisesEntry.exercises) { exercise in
                                ExerciseItemView(exerciseWithParticipationStatus: exercise, onClick: {

                                })
                                        .frame(maxWidth: .infinity)
                                        .padding(.horizontal, 8)
                            }
                        }
                    }
                }
            }
        }
    }

    private func areWeeklyExercisesExpanded(dict: [Date?: Bool], weeklyExercises: WeeklyExercises) -> Bool {
        switch weeklyExercises {
        case .BoundToWeek(firstDayOfWeek: let firstDayOfWeek, _, _):
            let daysDiff = Calendar.current.dateComponents([.day], from: firstDayOfWeek, to: Date()).day ?? 0
            let defaultValue = daysDiff < 14
            return dict[firstDayOfWeek] ?? defaultValue
        case .Unbound(_):
            let defaultValue = true
            return dict[nil] ?? defaultValue
        }
    }
}

private struct ExerciseWeekSectionHeaderView: View {
    let weeklyExercises: WeeklyExercises

    private let text: String

    init(weeklyExercises: WeeklyExercises) {
        self.weeklyExercises = weeklyExercises

        switch weeklyExercises {
        case .Unbound:
            text = NSLocalizedString("course_ui_exercise_list_unbound_week_header", comment: "Section header for the exercises that are not bound to a week.")
        case .BoundToWeek(firstDayOfWeek: let firstDayOfWeek, lastDayOfWeek: let lastDayOfWeek, _):
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            let fromText = dateFormatter.string(from: firstDayOfWeek)
            let toText = dateFormatter.string(from: lastDayOfWeek)

            let format = NSLocalizedString("course_ui_exercise_list_week_header", comment: "Display date range from week1 to week2")

            text = String.localizedStringWithFormat(format, fromText, toText)
        }

    }

    var body: some View {
        Text(text)
    }
}

/**
 * Display a single exercise.
 * The exercise is displayed in a card with an icon specific to the exercise type.
 */
private struct ExerciseItemView: View {
    let exerciseWithParticipationStatus: ExerciseWithParticipationStatus
    let onClick: () -> Void

    var body: some View {
        let cardShape = RoundedRectangle(cornerRadius: 10, style: .continuous)

        ZStack {
            VStack(spacing: 8) {
                HStack {
                    ZStack {
                        ExerciseTypeIconView(exercise: exerciseWithParticipationStatus.exercise)
                                .frame(width: 60, height: 60)
                                .padding([.leading, .top], 8)
                    }
                            .frame(width: 80, height: 80)

                    ExerciseDataTextView(
                            exercise: exerciseWithParticipationStatus.exercise,
                            participationStatus: exerciseWithParticipationStatus.participationStatus
                    )
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 8)
                }
                        .frame(maxWidth: .infinity)

                //Display a row of chips
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(exerciseWithParticipationStatus.categoryChips) { chip in
                            ExerciseCategoryChip(data: chip)
                        }
                    }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 8)
                }
                        .frame(maxWidth: .infinity)
            }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
        }
                .clipShape(cardShape)
                .background(
                        cardShape
                                .stroke(Color.outline)
                )
                .background(
                        cardShape
                                .fill(Color.primaryContainer.surface)
                )
    }
}

private struct ExerciseTypeIconView: View {

    let icon: String

    init(exercise: Exercise) {
        switch exercise {
        case .FileUpload(exercise: _): icon = "square.and.arrow.up"
        case .Modeling(exercise: _): icon = "compass.drawing"
        case .Programming(exercise: _): icon = "terminal"
        case .Quiz(exercise: _): icon = "questionmark.bubble"
        case .Text(exercise: _): icon = "note.text"
        case .Unknown(exercise: _): icon = "exclamationmark.triangle"
        }
    }

    var body: some View {
        Image(systemName: icon)
                .resizable()
                .scaledToFit()
    }
}

/**
 * Displays the exercise title, the due data and the participation info. The participation info is automatically updated.
 */
private struct ExerciseDataTextView: View {
    let exercise: Exercise
    let participationStatus: ParticipationStatus

    let dueDateText: String

    init(exercise: Exercise, participationStatus: ParticipationStatus) {
        self.exercise = exercise
        self.participationStatus = participationStatus

        let formatter = RelativeDateTimeFormatter()

        if let dueDate = exercise.baseExercise.dueDate {
            let formattedDueDate = formatter.localizedString(for: dueDate, relativeTo: Date())
            dueDateText = String.localizedStringWithFormat(NSLocalizedString("course_ui_exercise_item_due_date_set", comment: ""), formattedDueDate)
        } else {
            dueDateText = NSLocalizedString("course_ui_exercise_item_due_date_not_set", comment: "")
        }
    }

    var body: some View {
        VStack {
            Text(verbatim: exercise.baseExercise.title ?? "")
                    .font(.title3)
                    .frame(maxWidth: .infinity, alignment: .leading)

            Text(dueDateText)
                    .font(.callout)
                    .frame(maxWidth: .infinity, alignment: .leading)

            switch participationStatus {
            case .QuizFinished(participation: let p), .Initialized(participation: let p), .Inactive(participation: let p), .ExerciseSubmitted(participation: let p):
                ExerciseResultView(
                        exercise: exercise, participation: p, result: nil, showUngradedResults: true, personal: true
                )
                        .frame(maxWidth: .infinity, alignment: .leading)
            default:
                Text(participationStatus.submissionResultStatusText)
                        .font(.callout)
                        .frame(maxWidth: .infinity, alignment: .leading)
            }

        }
    }
}

/**
 * Displays a colored rounded rectangle with the given text in it.
 */
private struct ExerciseCategoryChip: View {

    let data: ExerciseCategoryChipData

    var body: some View {
        let chipShape = RoundedRectangle(cornerRadius: 25, style: .continuous)
        ZStack {
            ZStack {
                switch data.text {
                case .Verbatim(text: let text): Text(verbatim: text)
                case .Localized(text: let text): Text(text)
                }
            }.padding(.all, 4)
        }
                .clipShape(chipShape)
                .background(
                        chipShape.fill(data.color)
                )
    }
}

private extension ParticipationStatus {
    var submissionResultStatusText: LocalizedStringKey {
        switch self {
        case .QuizNotInitialized: return "exercise_quiz_not_started"
        case .QuizActive: return "exercise_user_participating"
        case .QuizSubmitted: return "exercise_user_submitted"
        case .QuizNotStarted: return "exercise_quiz_not_started"
        case .QuizNotParticipated: return "exercise_user_not_participated"
        case .NoTeamAssigned: return "exercise_user_not_assigned_to_team"
        case .Uninitialized: return "exercise_user_not_started_exercise"
        case .ExerciseActive: return "exercise_exercise_not_submitted"
        case .ExerciseMissed: return "exercise_exercise_missed_deadline"
        default: return ""
        }
    }
}
