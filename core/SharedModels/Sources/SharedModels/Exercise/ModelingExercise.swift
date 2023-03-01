import Foundation

public struct ModelingExercise: BaseExercise {
    public typealias SelfType = ModelingExercise
    public static var type: String {
        "modeling"
    }

    public var id: Int?
    public var title: String?
    public var shortName: String?
    public var maxPoints: Float?
    public var bonusPoints: Float?
//    public var releaseDate: Date?
    public var dueDate: Date?
    public var assessmentDueDate: Date?
    public var difficulty: Difficulty?
    public var mode: Mode = .INDIVIDUAL
    public var categories: [Category]? = []
    public var visibleToStudents: Bool?
    public var teamMode: Bool?
    public var problemStatement: String?
    public var assessmentType: AssessmentType?
    public var allowComplaintsForAutomaticAssessments: Bool?
    public var allowManualFeedbackRequests: Bool?
    public var includedInOverallScore: IncludedInOverallScore = .INCLUDED_COMPLETELY
    public var exampleSolutionPublicationDate: Date?
    public var studentParticipations: [Participation]?
    public var attachments: [Attachment]? = []

    public var diagramType: UMLDiagramType?
    public var exampleSolutionModel: String?
    public var exampleSolutionExplanation: String?

    public func copyWithUpdatedParticipations(newParticipations: [Participation]) -> ModelingExercise {
        var clone = self
        clone[keyPath: \.studentParticipations] = newParticipations
        return clone
    }
}

public enum UMLDiagramType: String, Decodable {
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