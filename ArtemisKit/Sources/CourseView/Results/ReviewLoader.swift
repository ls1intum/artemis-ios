import Common
import Foundation
import SharedModels

struct ReviewExercise: Decodable {
    struct Course: Decodable { let id: Int?; let accuracyOfScores: Int? }
    struct ExamGroup: Decodable { }
    let id: Int
    let type: String
    let title: String?
    let course: Course?
    let exerciseGroup: ExamGroup?
    let dueDate: Date?
    let maxPoints: Double?
    let bonusPoints: Double?
    let assessmentType: String?
    var assessmentDueDate: Date?
    let buildAndTestStudentSubmissionsAfterDueDate: Date?
    let diagramType: String?
    let studentParticipations: [ReviewParticipation]?
    let exampleSolutionPublicationDate: Date?
    let exampleSolution: String?
    let exampleSolutionModel: String?
    let exampleSolutionExplanation: String?
}
struct ReviewDocument {
    let reference: ReviewReference
    let exercise: ReviewExercise
    let submission: ReviewSubmission
    let result: ReviewResult
    var feedback: [StudentFeedback]
    var quiz: DTO.StudentQuizParticipation?
    var practice: Bool?

    var isLate: Bool? {
        let individual = exercise.studentParticipations?.first(where: { $0.id == reference.participationID })?.individualDueDate
        return ReviewDeadline.isLate(submitted: submission.submissionDate, due: exercise.dueDate, individual: individual)
    }
    var assessmentState: ReviewAssessmentState {
        let practice = self.practice ?? (exercise.studentParticipations?.first(where: { $0.id == reference.participationID })?.testRun == true)
        return .resolve(.init(exerciseType: exercise.type, exerciseAssessment: exercise.assessmentType, resultAssessment: result.assessmentType,
                              completion: result.completionDate, successful: result.successful, practice: practice,
                              assessmentDue: exercise.assessmentDueDate, rebuild: exercise.buildAndTestStudentSubmissionsAfterDueDate), now: .now)
    }
    var preliminary: Bool { assessmentState == .preliminary }
}
struct ReviewLoader {
    let reader: any ReviewReading
    private struct Details: Decodable { let exercise: ReviewExercise }
    private struct Source {
        let submission: ReviewSubmission
        var result: ReviewResult?
        var quiz: DTO.StudentQuizParticipation?
        var practice: Bool?
    }
    func load(_ reference: ReviewReference) async throws -> ReviewDocument {
        guard reader.isCurrent else { throw ReviewError.sessionChanged }
        let exercise = try await reader.read(Details.self, path: "/api/exercise/exercises/\(reference.exerciseID)/details").exercise
        guard exercise.id == reference.exerciseID, exercise.exerciseGroup == nil,
              exercise.course?.id == nil || exercise.course?.id == reference.courseID else { throw ReviewError.identity }
        let source = try await assessedSource(reference, exercise: exercise)
        let result = source.result ?? source.submission.results?.compactMap { $0 }.first(where: { $0.id == reference.resultID })
        guard let result, result.id == reference.resultID else { throw ReviewError.identity }
        let feedback: [StudentFeedback]
        if exercise.type == "quiz" {
            feedback = []
        } else if exercise.type == "modeling" {
            feedback = result.feedbacks ?? []
        } else {
            let path = "/api/assessment/participations/\(reference.participationID)/results/\(reference.resultID)/details"
            feedback = try await reader.read([StudentFeedback].self, path: path)
        }
        guard reader.isCurrent, !Task.isCancelled else { throw ReviewError.sessionChanged }
        return ReviewDocument(reference: reference, exercise: exercise, submission: source.submission,
                              result: result, feedback: feedback, quiz: source.quiz, practice: source.practice)
    }

    private func assessedSource(_ reference: ReviewReference, exercise: ReviewExercise) async throws -> Source {
        switch exercise.type {
        case "text":
            let path = "/api/text/participations/\(reference.participationID)/text-editor?resultId=\(reference.resultID)"
            return try await participationSource(reference, path: path)
        case "programming":
            let path = "/api/programming/programming-exercise-participations/\(reference.participationID)/student-participation-with-all-results"
            return try await participationSource(reference, path: path)
        case "modeling": return try await modelingSource(reference)
        case "quiz": return try await quizSource(reference)
        case "file-upload":
            guard let participation = exercise.studentParticipations?.first(where: { $0.id == reference.participationID }) else { throw ReviewError.identity }
            return Source(submission: try participation.assessedSubmission(submissionID: reference.submissionID, resultID: reference.resultID), practice: participation.testRun)
        default: throw ReviewError.identity
        }
    }

    private func participationSource(_ reference: ReviewReference, path: String) async throws -> Source {
        let participation = try await reader.read(ReviewParticipation.self, path: path)
        guard participation.id == reference.participationID else { throw ReviewError.identity }
        return Source(submission: try participation.assessedSubmission(submissionID: reference.submissionID, resultID: reference.resultID), practice: participation.testRun)
    }

    private func modelingSource(_ reference: ReviewReference) async throws -> Source {
        let submissions = try await reader.read([ReviewSubmission].self, path: "/api/modeling/participations/\(reference.participationID)/submissions-with-results")
        let participation = ReviewParticipation(id: reference.participationID, submissions: submissions)
        let submission = try participation.assessedSubmission(submissionID: reference.submissionID, resultID: reference.resultID)
        guard let result = submission.results?.compactMap({ $0 }).first(where: { $0.id == reference.resultID }) else { throw ReviewError.identity }
        if result.feedbacks?.isEmpty == false || result.assessmentType?.hasPrefix("AUTOMATIC") == true {
            return Source(submission: submission, result: result)
        }
        let resultPath = "/api/modeling/modeling-submissions/\(reference.submissionID)/result?resultId=\(reference.resultID)"
        let assessment = try await reader.read(ReviewResult.self, path: resultPath)
        guard assessment.id == reference.resultID else { throw ReviewError.identity }
        return Source(submission: submission, result: assessment)
    }

    private func quizSource(_ reference: ReviewReference) async throws -> Source {
        let path = "/api/quiz/quiz-exercises/\(reference.exerciseID)/participations/\(reference.participationID)/result?submissionId=\(reference.submissionID)"
        let data = try await reader.data(path)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .customISO8601
        let participation = try decoder.decode(ReviewParticipation.self, from: data)
        guard participation.id == reference.participationID else { throw ReviewError.identity }
        let submission = try participation.assessedSubmission(submissionID: reference.submissionID, resultID: reference.resultID)
        let quiz = try decoder.decode(DTO.StudentQuizParticipation.self, from: data)
        return Source(submission: submission, quiz: quiz, practice: participation.testRun)
    }
}
