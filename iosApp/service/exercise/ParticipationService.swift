import Foundation
import RxSwift
import Model

protocol ParticipationService {
    /**
     * Subscribed to the users personal participations
     */
    var personalSubmissionUpdater: Observable<Result> { get }

    /**
     * @param isPersonalParticipation whether the participation belongs to the user (by being a student) or not (by being an instructor)
     */
    func getLatestPendingSubmissionByParticipationIdObservable(participationId: Int, exerciseId: Int, personal: Bool, fetchPending: Bool) -> Observable<ProgrammingSubmissionStateData?>

    /**
     * Subscribing for general changes in a participation object. This will triggered if a new result is received by the service.
     * A received object will be the full participation object including all results and the exercise.
     *
     * **See also:** [js source](https://github.com/ls1intum/Artemis/blob/5c13e2e1b5b6d81594b9123946f040cbf6f0cfc6/src/main/webapp/app/overview/participation-websocket.service.ts#L228)
     */
    func subscribeForParticipationChanges() -> Observable<StudentParticipation>
}

enum ProgrammingSubmissionStateData {
    // The last submission of participation has a result.
    case NoPendingSubmission(participationId: Int)

    // The submission was createvd on the server, we assume that the build is running within an expected time frame.
    case IsBuildingPendingSubmission(participationId: Int, submission: Submission)

    // A failed submission is a pending submission that has not received a result within an expected time frame.
    case FailedSubmission(participationId: Int)
}
