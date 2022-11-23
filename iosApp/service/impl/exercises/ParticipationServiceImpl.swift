import Foundation
import RxSwift
import Alamofire
import Model
import Data
import Device

/**
 * From: https://github.com/ls1intum/Artemis/blob/5c13e2e1b5b6d81594b9123946f040cbf6f0cfc6/src/main/webapp/app/overview/participation-websocket.service.ts
 */
class ParticipationServiceImpl: ParticipationService {

    private static let PERSONAL_PARTICIPATION_TOPIC = "/user/topic/newResults"
    private static let PERSONAL_NEW_SUBMISSIONS_TOPIC = "/user/topic/newSubmissions"

    private static func exerciseParticipationTopic(exerciseId: Int) -> String {
        "/topic/exercise/" + String(exerciseId) + "/newResults"
    }

    private static func exerciseNewSubmissionsTopic(exerciseId: Int) -> String {
        "/topic/exercise/" + String(exerciseId) + "/newSubmissions"
    }

    private let websocketProvider: WebsocketProvider
    private let serverCommunicationProvider: ServerCommunicationProvider
    private let networkStatusProvider: NetworkStatusProvider
    private let accountService: AccountService
    private let jsonProvider: JsonProvider

    var personalSubmissionUpdater: Observable<Result>

    private var personalNewSubmissionsUpdater: Observable<WebsocketProgrammingSubmissionMessage>

    init(websocketProvider: WebsocketProvider, serverCommunicationProvider: ServerCommunicationProvider, networkStatusProvider: NetworkStatusProvider, accountService: AccountService, jsonProvider: JsonProvider) {
        self.websocketProvider = websocketProvider
        self.serverCommunicationProvider = serverCommunicationProvider
        self.networkStatusProvider = networkStatusProvider
        self.accountService = accountService
        self.jsonProvider = jsonProvider

        personalSubmissionUpdater = websocketProvider
                .subscribe(channel: ParticipationServiceImpl.PERSONAL_PARTICIPATION_TOPIC, type: Result.self)
                .replay(0)
                .refCount()


        personalNewSubmissionsUpdater = websocketProvider
                .subscribe(channel: ParticipationServiceImpl.PERSONAL_NEW_SUBMISSIONS_TOPIC, type: WebsocketProgrammingSubmissionMessage.self)
                .replay(1)
                .refCount()
    }

    func getLatestPendingSubmissionByParticipationIdObservable(participationId: Int, exerciseId: Int, personal: Bool, fetchPending: Bool) -> Observable<ProgrammingSubmissionStateData?> {
        let newSubmissionsUpdater: Observable<WebsocketProgrammingSubmissionMessage>
        if personal {
            newSubmissionsUpdater = personalNewSubmissionsUpdater
        } else {
            newSubmissionsUpdater = websocketProvider
                    .subscribe(
                            channel: ParticipationServiceImpl.exerciseNewSubmissionsTopic(exerciseId: exerciseId),
                            type: WebsocketProgrammingSubmissionMessage.self
                    )
        }

        //Flow that emits when the websocket sends new data
        let updatingObservable: Observable<ProgrammingSubmissionStateData?> =
                newSubmissionsUpdater
                        .map { [self] message in
                            switch message {
                            case .error(error: let error):
                                return Observable<ProgrammingSubmissionStateData?>.of(ProgrammingSubmissionStateData.FailedSubmission(participationId: error.participationId ?? 0))
                            case .submission(submission: let submission):
                                //Round to seconds, it does not really matter
                                let remainingTime = Int(
                                        getExpectedRemainingTimeForBuild(submission: submission)
                                )

                                //Wait for the submission updater to emit a result for the participation we are interested in
                                let submissionUpdater: Observable<Result>
                                if personal {
                                    submissionUpdater = personalSubmissionUpdater
                                } else {
                                    submissionUpdater = websocketProvider.subscribe(
                                            channel: ParticipationServiceImpl.exerciseParticipationTopic(exerciseId: exerciseId),
                                            type: Result.self
                                    )
                                }

                                return Observable<ProgrammingSubmissionStateData?>
                                        .of(ProgrammingSubmissionStateData.IsBuildingPendingSubmission(participationId: participationId, submission: submission))
                                        .concat(
                                                submissionUpdater
                                                        .filter { it in
                                                            it.participation?.baseParticipation.id == participationId
                                                        }
                                                        .map { _ in
                                                            ()
                                                        } // Map to Void, we are not interested in the value
                                                        .timeout(RxTimeInterval.seconds(remainingTime), other: Observable.of(nil), scheduler: MainScheduler())
                                                        .map { result in
                                                            if result == nil {
                                                                // The server sends the latest submission without a result - so it could be that the result is too old. In this case the error is shown directly.
                                                                return .FailedSubmission(participationId: participationId)
                                                            } else {
                                                                //The server has sent the result.
                                                                return .NoPendingSubmission(participationId: participationId)
                                                            }
                                                        }
                                        )

                            }
                        }
                        .switchLatest()

        if (fetchPending) {
            let initialObservable: Observable<ProgrammingSubmissionStateData?> = fetchLatestPendingSubmissionByParticipationId(participationId: participationId)
                    .map { submission in
                        ProgrammingSubmissionStateData.IsBuildingPendingSubmission(
                                participationId: participationId,
                                submission: submission
                        )
                    }
            return Observable.merge(initialObservable, updatingObservable)
        } else {
            return updatingObservable
        }
    }

    /**
     * Fetch the latest pending submission for a participation, which means:
     * - Submission is the newest one (by submissionDate)
     * - Submission does not have a result (yet)
     * - Submission is not older than DEFAULT_EXPECTED_RESULT_ETA (in this case it could be that never a result will come due to an error)
     *
     * @param participationId
     */
    private func fetchLatestPendingSubmissionByParticipationId(participationId: Int) -> Observable<Submission> {
        Observable
                .combineLatest(
                        serverCommunicationProvider.serverUrl,
                        accountService.authenticationData
                )
                .transformLatest { [self] sub, data in
                    let (serverUrl, authData) = data

                    switch authData {
                    case .NotLoggedIn: ()
                    case .LoggedIn(authToken: let authToken, account: _):
                        try? await sub.sendAll(
                                publisher:
                                retryOnInternet(connectivity: networkStatusProvider.currentNetworkStatus, perform: { [self] in
                                    let headers: HTTPHeaders = [
                                        .contentType("*/*"),
                                        .authorization(bearerToken: authToken)
                                    ]

                                    return await performNetworkCall {
                                        let bodyString = try await AF.request(serverUrl + "api" + "programming-exercise-participations" + String(participationId) + "latest-pending-submission", headers: headers)
                                                .serializingString()
                                                //                                                .serializingDecodable(Submission?.self, decoder: jsonProvider.decoder)
                                                .value

                                        //TODO: This returns a html doc
                                        return try jsonProvider.decoder.decode(Submission?.self, from: Data(bodyString.utf8))
                                    }
                                })
                        )
                    }
                }
                .filter { it in
                    it.isSuccess()
                }
                .map { (it: DataState<Submission?>) in
                    try! it.orThrow()
                }
                .compactMap {
                    $0
                }
    }

    func subscribeForParticipationChanges() -> RxSwift.Observable<StudentParticipation> {
        Observable.create { sub in
            Disposables.create()
        }
    }

    private func getExpectedRemainingTimeForBuild(submission: Submission) -> TimeInterval {
        TimeInterval(120) - TimeInterval(Date().timeIntervalSince(submission.baseSubmission.submissionDate?.date ?? Date()))
    }
}

fileprivate struct ProgrammingSubmissionError: Decodable {
    let error: String
    var participationId: Int? = 0
}

fileprivate enum WebsocketProgrammingSubmissionMessage: Decodable {

    private enum Keys: String, CodingKey {
        case error
    }

    case error(error: ProgrammingSubmissionError)
    case submission(submission: Submission)

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        if container.contains(Keys.error) {
            self = .error(error: try ProgrammingSubmissionError(from: decoder))
        } else {
            self = .submission(submission: try Submission(from: decoder))
        }
    }
}
