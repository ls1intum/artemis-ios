//
//  File.swift
//  
//
//  Created by Sven Andabaka on 11.04.23.
//

import Foundation
import SharedModels
import Common

protocol ExerciseService {

    func getExercise(exerciseId: Int) async -> DataState<Exercise>
}

enum ExerciseServiceFactory {

    static let shared: ExerciseService = ExerciseServiceImpl()
}
