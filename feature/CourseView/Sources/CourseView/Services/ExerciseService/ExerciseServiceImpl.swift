//
//  ExerciseServiceImpl.swift
//  
//
//  Created by Sven Andabaka on 11.04.23.
//

import Foundation
import Common
import APIClient
import SharedModels

class ExerciseServiceImpl: ExerciseService {
    
    let client = APIClient()

    struct GetExerciseRequest: APIRequest {
        typealias Response = Exercise

        var exerciseId: Int

        var method: HTTPMethod {
            return .get
        }

        var resourceName: String {
            return "api/exercises/\(exerciseId)/details"
        }
    }
    
    func getExercise(exerciseId: Int) async -> DataState<Exercise> {
        let result = await client.sendRequest(GetExerciseRequest(exerciseId: exerciseId))

        switch result {
        case .success((let response, _)):
            return .done(response: response)
        case .failure(let error):
            return .failure(error: UserFacingError(error: error))
        }
    }
}
