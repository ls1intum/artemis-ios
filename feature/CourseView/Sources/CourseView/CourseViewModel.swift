import Foundation
import SharedModels
import Common
import APIClient

@MainActor
class CourseViewModel: ObservableObject {

    @Published var course: DataState<Course> = DataState.loading

    init(course: Course) {
        Task {
            await loadCourse(course)
        }

        //        /*
        //        * Holds a flow of the latest participation status for each exercise (associated by the exercise id)
        //        */
        //        let exerciseWithParticipationStatusObservable: Observable<DataState<[ExerciseWithParticipationStatus]>> =
        //                coursePublisher
        //                        .map { courseDataState in
        //                            courseDataState.bind { it in
        //                                it.exercises ?? []
        //                            }
        //                        }
        //                        .map { (exercisesDataState: DataState<[Exercise]>) in
        //                            switch exercisesDataState {
        //                            case .done(response: let exercises):
        //                                var exercisesById = exercises.reduce(into: [Int: Exercise]()) {
        //                                    $0[$1.baseExercise.id ?? 0] = $1
        //                                }
        //
        //                                var participationStatusMap: [Int: ExerciseWithParticipationStatus] =
        //                                        exercises.reduce(into: [Int: ExerciseWithParticipationStatus]()) { map, it in
        //                                            map[it.baseExercise.id ?? 0] = ExerciseWithParticipationStatus(exercise: it, participationStatus: it.baseExercise.computeParticipationStatus(testRun: nil))
        //                                        }
        //
        //                                return Observable.of(DataState.done(response: Array(participationStatusMap.values)))
        //                                        .concat(
        //                                                participationService
        //                                                        .personalSubmissionUpdater
        //                                                        .filterMap { latestResult in
        //                                                            guard let participation: Participation = latestResult.participation else {
        //                                                                return .ignore
        //                                                            }
        //
        //                                                            guard let associatedExerciseId = participation.baseParticipation.exercise?.baseExercise.id else {
        //                                                                return .ignore
        //                                                            }
        //
        //                                                            guard let associatedExercise = exercisesById[associatedExerciseId] else {
        //                                                                return .ignore
        //                                                            }
        //
        //                                                            return .map((participation, associatedExerciseId, associatedExercise))
        //                                                        }
        //                                                        .map { (data: (Participation, Int, Exercise)) in
        //                                                            let (participation, associatedExerciseId, associatedExercise) = data
        //
        //                                                            let currentAssociatedExerciseParticipations = associatedExercise.baseExercise.studentParticipations
        //
        //                                                            let updatedParticipations =
        //                                                                    //Replace the updated participation
        //                                                                    currentAssociatedExerciseParticipations?.map { oldParticipation in
        //                                                                        if oldParticipation.baseParticipation.id == participation.baseParticipation.id {
        //                                                                            return participation
        //                                                                        } else {
        //                                                                            return oldParticipation
        //                                                                        }
        //                                                                    } ?? //The new participations are just the one we just received
        //                                                                            [participation]
        //
        //                                                            //Replace the exercise
        //                                                            let newExercise = associatedExercise.copyWithUpdatedParticipations(
        //                                                                    newParticipations: updatedParticipations
        //                                                            )
        //
        //                                                            exercisesById[associatedExerciseId] = newExercise
        //
        //                                                            participationStatusMap[associatedExerciseId] =
        //                                                                    ExerciseWithParticipationStatus(
        //                                                                            exercise: newExercise,
        //                                                                            participationStatus: newExercise.baseExercise.computeParticipationStatus(testRun: nil)
        //                                                                    )
        //
        //                                                            return DataState.done(response: Array(participationStatusMap.values))
        //                                                        }
        //                                        )
        //                            default:
        //                                return Observable.of(
        //                                        exercisesDataState.bind { _ in
        //                                            []
        //                                        }
        //                                )
        //                            }
        //                        }
        //                        .switchLatest()
        //
        //        exerciseWithParticipationStatusObservable
        //                .map { exercisesDataState in
        //                    exercisesDataState.bind { exercisesWithParticipationState in
        //                        // Group the exercise based on their start of the week day (most likely monday)
        //                        Dictionary<Date?, [ExerciseWithParticipationStatus]>(grouping: exercisesWithParticipationState, by: { (exerciseWithParticipationState: ExerciseWithParticipationStatus) in
        //                            let exercise = exerciseWithParticipationState.exercise
        //                            guard let releaseDate = exercise.baseExercise.dueDate else {
        //                                return nil
        //                            }
        //
        //                            return releaseDate.dateAt(.startOfWeek)
        //                        })
        //                                .map { entry in
        //                                    let firstDayOfWeek: Date? = entry.key
        //                                    let exercises: [ExerciseWithParticipationStatus] = entry.value
        //
        //                                    if let f = firstDayOfWeek {
        //                                        let lastDayOfWeek = f + 6.days
        //                                        return WeeklyExercises.BoundToWeek(firstDayOfWeek: f, lastDayOfWeek: lastDayOfWeek, exercises: exercises)
        //                                    } else {
        //                                        return WeeklyExercises.Unbound(exercises: exercises)
        //                                    }
        //                                }
        //                                .sorted()
        //                    }
        //                }
        //                .publisher
        //                .replaceWithDataStateError()
        //                .receive(on: DispatchQueue.main)
        //                .assign(to: &$exercisesGroupedByWeek)
    }

    func loadCourse(_ course: Course) async {
        self.course = await CourseServiceFactory.shared.getCourse(courseId: course.id) // TODO: why optional
    }
}

// struct ExerciseWithParticipationStatus: Identifiable {
//    typealias ID = Int
//
//    let exercise: Exercise
//    let participationStatus: ParticipationStatus
//    var id: ID {
//        exercise.baseExercise.id ?? 0
//    }
//
//    let categoryChips: [ExerciseCategoryChipData]
//
//    init(exercise: Exercise, participationStatus: ParticipationStatus) {
//        self.exercise = exercise
//        self.participationStatus = participationStatus
//
//        categoryChips = ExerciseWithParticipationStatus.collectExerciseCategoryChips(exercise: exercise)
//    }
//
//    /**
//     * A list of the chips that are displayed in the ui from the data available in the exercise.
//     */
//    private static func collectExerciseCategoryChips(exercise: Exercise) -> [ExerciseCategoryChipData] {
//        let liveQuizChips: [ExerciseCategoryChipData]
//        if exercise.baseExercise is QuizExercise && (exercise.baseExercise as! QuizExercise).status == .ACTIVE {
//            liveQuizChips = [ExerciseCategoryChipData(text: .Localized(text: "exercise_live_quiz"), color: Color(hexValue: 0xff28a745))]
//        } else {
//            liveQuizChips = []
//        }
//
//        let difficultyChips: [ExerciseCategoryChipData]
//        if let difficulty = exercise.baseExercise.difficulty {
//            switch difficulty {
//            case .EASY: difficultyChips = [ExerciseCategoryChipData(text: .Localized(text: "exercise_difficulty_easy"), color: Color(hexValue: 0xff28a745))]
//            case .MEDIUM: difficultyChips = [ExerciseCategoryChipData(text: .Localized(text: "exercise_difficulty_medium"), color: Color(hexValue: 0xffffc107))]
//            case .HARD: difficultyChips = [ExerciseCategoryChipData(text: .Localized(text: "exercise_difficulty_hard"), color: Color(hexValue: 0xffdc3545))]
//            }
//        } else {
//            difficultyChips = []
//        }
//
//        let bonusChips: [ExerciseCategoryChipData]
//        if exercise.baseExercise.includedInOverallScore == .INCLUDED_AS_BONUS {
//            bonusChips = [ExerciseCategoryChipData(text: .Localized(text: "exercise_is_bonus"), color: Color(hexValue: 0xFF00FFFF))]
//        } else {
//            bonusChips = []
//        }
//
//        let categoryChips = (exercise.baseExercise.categories ?? []).map { category in
//            ExerciseCategoryChipData(text: .Verbatim(text: category.category), color: Color(hexValue: category.colorCode ?? 0xFFFFFFFF))
//        }
//
//        return liveQuizChips + categoryChips + difficultyChips + bonusChips
//    }
// }
//
/// **
// * Struct that holds information about a chip displayed for an exercise.
// * For example the exercise difficulty (easy, hard, ...) or if it as an easy exercise
// */
// struct ExerciseCategoryChipData: Identifiable {
//    typealias ID = String
//    let text: TextType
//    let color: Color
//    var id: ID {
//        switch text {
//        case .Verbatim(text: let text): return text
//        case .Localized(text: let text): return text.key
//        }
//    }
//
//    /**
//     * There is probably an easier way to do this.
//     */
//    enum TextType {
//        case Verbatim(text: String)
//        case Localized(text: LocalizedStringResource)
//    }
// }
