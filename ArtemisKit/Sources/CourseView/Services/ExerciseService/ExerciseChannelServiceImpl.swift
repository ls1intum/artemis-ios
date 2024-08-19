//
//  ExerciseChannelServiceImpl.swift
//
//
//  Created by Anian Schleyer on 18.08.24.
//

import APIClient
import Common
import SharedModels

struct ExerciseChannelServiceImpl: ExerciseChannelService {

    let client = APIClient()

    struct GetExerciseChannelRequest: APIRequest {
        typealias Response = Channel

        let courseId: Int
        let exerciseId: Int

        var method: HTTPMethod {
            .get
        }

        var resourceName: String {
            "api/courses/\(courseId)/exercises/\(exerciseId)/channel"
        }
    }

    func getAssociatedChannel(for exerciseId: Int, in courseId: Int) async -> DataState<Channel> {
        let result = await client.sendRequest(GetExerciseChannelRequest(courseId: courseId, exerciseId: exerciseId))

        switch result {
        case let .success((response, _)):
            return .done(response: response)
        case let .failure(error):
            return .failure(error: UserFacingError(error: error))
        }
    }
}
