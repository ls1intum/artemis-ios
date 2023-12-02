//
//  ModelingExerciseViewModel.swift
//  
//
//  Created by Alexander Görtzen on 21.11.23.
//

import ApollonShared
import Common
import Foundation
import SharedModels

class ModelingExerciseViewModel: BaseViewModel {
    @Published var submission: BaseSubmission?
    @Published var umlModel: UMLModel?
    @Published var loading = false
    @Published var problemStatementURL: URLRequest

    var exercise: Exercise
    var participationId: Int

    init(exercise: Exercise, participationId: Int, problemStatementURL: URLRequest) {
        self.exercise = exercise
        self.participationId = participationId
        self.problemStatementURL = problemStatementURL
    }

    func initSubmission() async {
        guard submission == nil else {
            return
        }

        loading = true

        defer {
            loading = false
        }

        let exerciseService = ExerciseSubmissionServiceFactory.service(for: exercise)

        do {
            let response = try await exerciseService.getLatestSubmission(participationId: participationId)
            self.submission = response.baseSubmission
        } catch {
            log.error(String(describing: error))
        }
    }

    func setup() {
        guard let modelingSubmission = self.submission as? ModelingSubmission else {
            return
        }

        do {
            if let modelData = modelingSubmission.model?.data(using: .utf8) {
                umlModel = try JSONDecoder().decode(UMLModel.self, from: modelData)
            } else {
                // TODO: Initialize an empty UMLModel
            }
        } catch {
            log.error("Could not parse UML string: \(error)")
        }
    }

    func submitSubmission() async {
        guard var submitSubmission = submission as? ModelingSubmission, let umlModel else {
            return
        }

        let exerciseService = ExerciseSubmissionServiceFactory.service(for: exercise)

        do {
            let jsonData = try JSONEncoder().encode(umlModel)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                submitSubmission.model = jsonString
            }
            try await exerciseService.updateSubmission(exerciseId: exercise.id, submission: submitSubmission)
        } catch {
            log.error(String(describing: error))
        }
    }
}
