import Foundation

struct ModelingExercise: BaseExercise {
    typealias SelfType = ModelingExercise
    public static var type: String {
        "modeling"
    }

    var id: Int? = nil
    var title: String? = nil
    var shortName: String? = nil
    var maxPoints: Float? = nil
    var bonusPoints: Float? = nil
    var releaseDate: Date? = nil
    var dueDate: Date? = nil
    var assessmentDueDate: Date? = nil
    var difficulty: Difficulty? = nil
    var mode: Mode = .INDIVIDUAL
    var categories: [Category] = []
    var visibleToStudents: Bool? = nil
    var teamMode: Bool? = nil
    var problemStatement: String? = nil
    var assessmentType: AssessmentType? = nil
    var allowComplaintsForAutomaticAssessments: Bool? = nil
    var allowManualFeedbackRequests: Bool? = nil
    var includedInOverallScore: IncludedInOverallScore = .INCLUDED_COMPLETELY
    var exampleSolutionPublicationDate: Date? = nil
    var studentParticipations: [Participation]? = nil
    var attachments: [Attachment] = []

    var diagramType: UMLDiagramType? = nil
    var exampleSolutionModel: String? = nil
    var exampleSolutionExplanation: String? = nil

    func copyWithUpdatedParticipations(newParticipations: [Participation]) -> ModelingExercise {
        var clone = self
        clone[keyPath: \.studentParticipations] = newParticipations
        return clone
    }
}

enum UMLDiagramType: String, Decodable {
    case ClassDiagram
    case ObjectDiagram
    case ActivityDiagram
    case UseCaseDiagram
    case CommunicationDiagram
    case ComponentDiagram
    case DeploymentDiagram
    case PetriNet
    case SyntaxTree
    case Flowchart
}