import Foundation
import Factory
import RxSwift
import SwiftDate

class CourseViewController: ObservableObject {

    private let courseId: Int
    private let serverCommunicationProvider: ServerCommunicationProvider = Container.serverCommunicationProvider()
    private let accountService: AccountService = Container.accountService()
    private let networkStatusProvider: NetworkStatusProvider = Container.networkStatusProvider()
    private let courseService: CourseService = Container.courseService()
    private let participationService: ParticipationService = Container.participationService()

    private let requestReloadCourse = PublishSubject<Void>()

    @Published var course: DataState<Course> = DataState.loading
    @Published var exercisesGroupedByWeek: DataState<[WeeklyExercise]> = DataState.loading

    init(courseId: Int) {
        self.courseId = courseId

        let coursePublisher: Observable<DataState<Course>> = Observable
                .combineLatest(serverCommunicationProvider.serverUrl, accountService.authenticationData, requestReloadCourse.startWith(()))
                .transformLatest { [self] sub, data in
                    let (serverUrl, authData, _) = data

                    switch authData {
                    case .LoggedIn(authToken: let authToken, _):
                        try? await sub.sendAll(
                                publisher: retryOnInternet(connectivity: networkStatusProvider.currentNetworkStatus) { [self] in
                                    await courseService.getCourse(courseId: courseId, serverUrl: serverUrl, authToken: authToken)
                                }
                        )
                    case .NotLoggedIn:
                        sub.onNext(DataState.suspended(error: nil))
                    }
                }

        coursePublisher.publisher
                .replaceWithDataStateError()
                .receive(on: DispatchQueue.main)
                .assign(to: &$course)

        /*
        * Holds a flow of the latest participation status for each exercise (associated by the exercise id)
        */
        let exerciseWithParticipationStatusObservable: Observable<DataState<[ExerciseWithParticipationStatus]>> =
                coursePublisher
                        .map { courseDataState in
                            courseDataState.bind { it in
                                it.exercises ?? []
                            }
                        }
                        .transformLatest { [self] (sub, exercisesDataState: DataState<[Exercise]>) in
                            switch exercisesDataState {
                            case .done(response: let exercises):
                                var exercisesById = exercises.reduce(into: [Int: Exercise]()) {
                                    $0[$1.baseExercise.id ?? 0] = $1
                                }

                                var participationStatusMap: [Int: ExerciseWithParticipationStatus] =
                                        exercises.reduce(into: [Int: ExerciseWithParticipationStatus]()) { map, it in
                                            map[it.baseExercise.id ?? 0] = ExerciseWithParticipationStatus(exercise: it, participationStatus: it.baseExercise.computeParticipationStatus(testRun: nil))
                                        }

                                sub.onNext(DataState.done(response: Array(participationStatusMap.values)))

                                do {
                                    for try await latestSubmission in participationService
                                            .personalSubmissionUpdater
                                            .values {
                                        //Find the associated exercise, so that the submissions can be updated.
                                        guard let participation: Participation = latestSubmission.baseSubmission.participation else {
                                            continue
                                        }

                                        guard let associatedExerciseId = participation.baseParticipation.exercise?.baseExercise.id else {
                                            continue
                                        }

                                        guard let associatedExercise = exercisesById[associatedExerciseId] else {
                                            continue
                                        }

                                        let currentAssociatedExerciseParticipations = associatedExercise.baseExercise.studentParticipations

                                        let updatedParticipations =
                                                //Replace the updated participation
                                                currentAssociatedExerciseParticipations?.map { oldParticipation in
                                                    if oldParticipation.baseParticipation.id == participation.baseParticipation.id {
                                                        return participation
                                                    } else {
                                                        return oldParticipation
                                                    }
                                                } ?? //The new participations are just the one we just received
                                                        [participation]

                                        //Replace the exercise
                                        let newExercise = associatedExercise.copyWithUpdatedParticipations(
                                                newParticipations: updatedParticipations
                                        )

                                        exercisesById[associatedExerciseId] = newExercise

                                        participationStatusMap[associatedExerciseId] =
                                                ExerciseWithParticipationStatus(
                                                        exercise: newExercise,
                                                        participationStatus: newExercise.baseExercise.computeParticipationStatus(testRun: nil)
                                                )

                                        sub.onNext(DataState.done(response: Array(participationStatusMap.values)))
                                    }
                                } catch {
                                    //Should not happen
                                }
                            default:
                                sub.onNext(exercisesDataState.bind { _ in
                                    []
                                })
                            }
                        }

        exerciseWithParticipationStatusObservable
                .map { exercisesDataState in
                    exercisesDataState.bind { exercisesWithParticipationState in
                        // Group the exercise based on their start of the week day (most likely monday)
                        Dictionary<Date?, [ExerciseWithParticipationStatus]>(grouping: exercisesWithParticipationState, by: { (exerciseWithParticipationState: ExerciseWithParticipationStatus) in
                            let exercise = exerciseWithParticipationState.exercise
                            guard let releaseDate = exercise.baseExercise.dueDate else {
                                return nil
                            }

                            return releaseDate.dateAt(.startOfWeek)
                        })
                                .map { entry in
                                    let firstDayOfWeek: Date? = entry.key
                                    let exercises: [ExerciseWithParticipationStatus] = entry.value

                                    if let f = firstDayOfWeek {
                                        let lastDayOfWeek = f + 6.days
                                        return WeeklyExercise.BoundToWeek(firstDayOfWeek: f, lastDayOfWeek: lastDayOfWeek, exercises: exercises)
                                    } else {
                                        return WeeklyExercise.Unbound(exercises: exercises)
                                    }
                                }
                                .sorted()
                    }
                }
                .publisher
                .replaceWithDataStateError()
                .receive(on: DispatchQueue.main)
                .assign(to: &$exercisesGroupedByWeek)
    }

    func reloadCourse() {
        requestReloadCourse.onNext(())
    }
}

struct ExerciseWithParticipationStatus {
    let exercise: Exercise
    let participationStatus: ParticipationStatus
}

enum WeeklyExercise : Comparable{
    case BoundToWeek(firstDayOfWeek: Date, lastDayOfWeek: Date, exercises: [ExerciseWithParticipationStatus])
    case Unbound(exercises: [ExerciseWithParticipationStatus])

    private var dateToCompare: Date {
        switch self {
        case .BoundToWeek(firstDayOfWeek: let firstDayOfWeek, _, _):
            return firstDayOfWeek
        case .Unbound(_):
            return Date.distantFuture
        }
    }

    static func <(lhs: WeeklyExercise, rhs: WeeklyExercise) -> Bool {
        lhs.dateToCompare < rhs.dateToCompare
    }

    static func ==(lhs: WeeklyExercise, rhs: WeeklyExercise) -> Bool {
        lhs.dateToCompare == rhs.dateToCompare
    }
}

