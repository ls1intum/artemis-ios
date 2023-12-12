//
//  ModelingExerciseViewModel.swift
//  
//
//  Created by Alexander Görtzen on 21.11.23.
//

import ApollonShared
import Common
import Foundation
import ApollonShared
import SharedModels
import Common

class ModelingExerciseViewModel: BaseViewModel {

    @Published var problemStatementURL: URLRequest
    @Published var submission: BaseSubmission?
    @Published var umlModel: UMLModel?
    @Published var loading = false
    @Published var diagramTypeUnsupported = false

    var exercise: Exercise
    var participationId: Int
    var resultId: Int?
    var problemStatementURL: URLRequest?

    init(exercise: Exercise, participationId: Int, resultId: Int? = nil, problemStatementURL: URLRequest? = nil) {
        self.exercise = exercise
        self.participationId = participationId
        self.resultId = resultId
        self.problemStatementURL = problemStatementURL
    }

    func onAppear() async {
        guard submission == nil else {
            return
        }

        isLoading = true
        defer {
            isLoading = false
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
            log.error("Could not get modeling submission")
            return
        }

        do {
            if let modelData = modelingSubmission.model?.data(using: .utf8) {
                umlModel = try JSONDecoder().decode(UMLModel.self, from: modelData)
                guard let type = umlModel?.type, !UMLDiagramType.isDiagramTypeUnsupported(diagramType: type) else {
                    log.error("This diagram type is not yet supported")
                    diagramTypeUnsupported = true
                    return
                }
            } else {
                guard let modelingExercise = exercise.baseExercise as? ModelingExercise,
                      let type = modelingExercise.diagramType,
                      let umlDiagramType = ApollonShared.UMLDiagramType(rawValue: type.rawValue),
                      !UMLDiagramType.isDiagramTypeUnsupported(diagramType: umlDiagramType) else {
                    log.error("This diagram type is not yet supported")
                    diagramTypeUnsupported = true
                    return
                }
                umlModel = UMLModel(type: umlDiagramType)
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
