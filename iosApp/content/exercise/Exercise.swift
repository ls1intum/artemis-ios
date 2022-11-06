import Foundation

protocol Exercise {
    var id: Int? { get }
    var title: String? { get }
    var shortName: String? { get }
    var maxPoints: Float? { get }
    var bonusPoints: Float? { get }
    var releaseDate: Date? { get }
    var dueDate: Date? { get }
    var assessmentDueDate: Date? { get }
    var difficulty: Difficulty? { get }
    var mode: Mode { get }
    var categories: [Category] { get }
    var visibleToStudents: Bool? { get }
    var teamMode: Bool? { get }
    var problemStatement: String? { get }
    var assessmentType: AssessmentType? { get }
    var allowComplaintsForAutomaticAssessments: Bool? { get }
    var allowManualFeedbackRequests: Bool? { get }
    var includedInOverallScore: IncludedInOverallScore { get }
    var exampleSolutionPublicationDate: Date? { get }
    var studentParticipations: [Participation]? { get }

    // -------
    var attachments: [Attachment] { get }

    /**
     * Create a copy of this exercise with the participations field replaced.
     */
    func copyWithUpdatedParticipations(newParticipations: [Participation]) -> Exercise
}

enum Difficulty: String, Decodable {
    case EASY
    case MEDIUM
    case HARD
}

enum Mode: String, Decodable {
    case INDIVIDUAL
    case TEAM
}

// IMPORTANT NOTICE: The following strings have to be consistent with the ones defined in Exercise.java

enum IncludedInOverallScore: String, Decodable {
    case INCLUDED_COMPLETELY
    case INCLUDED_AS_BONUS
    case NOT_INCLUDED
}

enum ParticipationStatus {
    case QuizNotInitialized
    case QuizActive
    case QuizSubmitted
    case QuizNotStarted
    case QuizNotParticipated
    case QuizFinished(participation: Participation)
    case NoTeamAssigned
    case Uninitialized
    case Initialized(participation: Participation)

    case Inactive(participation: Participation)

    case ExerciseActive
    case ExerciseSubmitted(participation: Participation)
    case ExerciseMissed
}

enum AssessmentType: String, Decodable {
    case AUTOMATIC
    case SEMI_AUTOMATIC
    case MANUAL
}

struct Category: Decodable {
    let category: String
    let colorCode: Int64?

    init(from decoder: Decoder) {
        let string: String = try! decoder.singleValueContainer().decode(String.self)
        let impl = try! JSONDecoder().decode(CategoryImpl.self, from: Data(string.utf8))

        category = impl.category
        colorCode = Category.decodeColor(colorString: impl.color)
    }

    static func decodeColor(colorString: String) -> Int64? {
        if colorString.isEmpty || colorString == "null" {
            return nil
        }

        if !colorString.starts(with: "#") {
            return nil
        }

        let intCode = Int64(colorString.dropFirst(), radix: 16)
        return 0xff000000 + intCode!
    }
}

fileprivate struct CategoryImpl: Decodable {
    let category: String
    let color: String
}

extension Exercise {
    //-------------------------------------------------------------
    // Copy of https://github.com/ls1intum/Artemis/blob/5c13e2e1b5b6d81594b9123946f040cbf6f0cfc6/src/main/webapp/app/exercises/shared/exercise/exercise.utils.ts
    // TODO: Remove me once this is calculated on the server.

    func computeParticipationStatus(testRun: Bool?) -> ParticipationStatus {
        let studentParticipation: Participation?
        if (testRun == nil) {
            studentParticipation = (studentParticipations ?? []).first
        } else {
            let foo: [Participation] = studentParticipations ?? []
            studentParticipation = foo.first { it in
                if (it is StudentParticipation) {
                    return (it as! StudentParticipation).testRun == testRun
                } else {
                    return false
                }
            }
        }


        // For team exercises check whether the student has been assigned to a team yet
        // !!!! TODO: Not yet implemented
        //        if (teamMode == true && studentAssignedTeamIdComputed && !studentAssignedTeamId) {
        //            return ParticipationStatus.NO_TEAM_ASSIGNED
        //        }

        // Evaluate the participation status for quiz exercises.
        if (self is QuizExercise) {
            return participationStatusForQuizExercise(exercise: self as! QuizExercise)
        }

        // Evaluate the participation status for modeling, text and file upload exercises if the exercise has participations.
        if ((self is ModelingExercise || self is TextExercise || self is FileUploadExercise) && studentParticipation != nil) {
            return participationStatusForModelingTextFileUploadExercise(participation: studentParticipation!)
        }

        let initState = studentParticipation?.initializationState

        // The following evaluations are relevant for programming exercises in general and for modeling, text and file upload exercises that don't have participations.
        if (studentParticipation == nil ||
                initState == InitializationState.UNINITIALIZED ||
                initState == InitializationState.REPO_COPIED ||
                initState == InitializationState.REPO_CONFIGURED ||
                initState == InitializationState.BUILD_PLAN_COPIED ||
                initState == InitializationState.BUILD_PLAN_CONFIGURED
           ) {
            if (self is ProgrammingExercise && !isStartExerciseAvailable(exercise: self as! ProgrammingExercise) && testRun == nil || testRun == false) {
                return ParticipationStatus.ExerciseMissed
            } else {
                return ParticipationStatus.Uninitialized
            }
        } else if (studentParticipation!.initializationState == InitializationState.INITIALIZED) {
            return ParticipationStatus.Initialized(participation: studentParticipation!)
        }
        return ParticipationStatus.Inactive(participation: studentParticipation!)
    }

    private func isStartExerciseAvailable(exercise: ProgrammingExercise) -> Bool {
        exercise.dueDate == nil || Date() < exercise.dueDate!
    }


    private func participationStatusForQuizExercise(exercise: QuizExercise) -> ParticipationStatus {
        if (exercise.status == QuizStatus.CLOSED) {
            if (!(exercise.studentParticipations ?? []).isEmpty && !(exercise.studentParticipations!.first!.results ?? []).isEmpty) {
                return ParticipationStatus.QuizFinished(participation: exercise.studentParticipations!.first!)
            }

            return ParticipationStatus.QuizNotParticipated
        } else if (!(exercise.studentParticipations ?? []).isEmpty) {
            let initState = exercise.studentParticipations!.first!.initializationState
            if (initState == InitializationState.INITIALIZED) {
                return ParticipationStatus.QuizActive
            } else if (initState == InitializationState.FINISHED) {
                return ParticipationStatus.QuizSubmitted
            }
        } else if (exercise.quizBatches.contains { it in
            it.started == true
        }) {
            return ParticipationStatus.QuizNotInitialized
        }
        return ParticipationStatus.QuizNotStarted
    }

    private func participationStatusForModelingTextFileUploadExercise(participation: Participation) -> ParticipationStatus {
        if (participation.initializationState == InitializationState.INITIALIZED) {
            if (hasDueDataPassed(participation: participation)) {
                return ParticipationStatus.ExerciseMissed
            } else {
                return ParticipationStatus.ExerciseActive
            }
        } else if (participation.initializationState == InitializationState.FINISHED) {
            return ParticipationStatus.ExerciseSubmitted(participation: participation)
        } else {
            return ParticipationStatus.Uninitialized
        }
    }

    private func hasDueDataPassed(participation: Participation) -> Bool {
        if (dueDate == nil) {
            return false
        } else {
            let dueDate = getDueDate(participation: participation)
            if dueDate == nil {
                return false
            }
            return dueDate! > Date()
        }
    }

    func getDueDate(participation: Participation) -> Date? {
        if (dueDate == nil) {
            return nil
        } else {
            return participation.initializationDate ?? dueDate
        }
    }
}