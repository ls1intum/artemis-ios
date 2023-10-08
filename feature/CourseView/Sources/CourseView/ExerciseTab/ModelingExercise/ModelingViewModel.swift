import Foundation
import SwiftUI
import Combine
import SharedModels
import Common
import APIClient
import ApollonShared

class ModelingViewModel: ObservableObject {
    @Published var submission: BaseSubmission?
    @Published var umlModel: UMLModel?
    @Published var loading = false
    @Published var error: Error?
    
    var exercise: Exercise
    var participationId: Int
    
    init(exercise: Exercise, participationId: Int) {
        self.exercise = exercise
        self.participationId = participationId
    }
    
    
    @MainActor
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
            self.error = error
            log.error(String(describing: error))
        }
    }
    
    @MainActor
    func setup() {
        guard let modelingSubmission = self.submission as? ModelingSubmission,
              let modelData = modelingSubmission.model?.data(using: .utf8) else {
            return
        }
        do {
            umlModel = try JSONDecoder().decode(UMLModel.self, from: modelData)
        } catch {
            log.error("Could not parse UML string: \(error)")
        }
    }
}
