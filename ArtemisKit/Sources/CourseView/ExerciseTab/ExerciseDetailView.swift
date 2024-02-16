//
//  ExerciseDetailView.swift
//
//
//  Created by Sven Andabaka on 23.03.23.
//

import SwiftUI
import SharedModels
import UserStore
import DesignLibrary
import Common
import SharedServices
import Navigation

public struct ExerciseDetailView: View {
    @EnvironmentObject var navigationController: NavigationController

    @State private var webViewHeight = CGFloat.s
    @State private var urlRequest: URLRequest
    @State private var isWebViewLoading = true

    @State private var exercise: DataState<Exercise>

    @State private var showFeedback = false

    @State private var latestResultId: Int?
    @State private var participationId: Int?

    private let exerciseId: Int
    private let courseId: Int

    public init(course: Course, exercise: Exercise) {
        self._exercise = State(wrappedValue: .done(response: exercise))
        self._urlRequest = State(wrappedValue: URLRequest(url: URL(string: "/courses/\(course.id)/exercises/\(exercise.id)/problem-statement", relativeTo: UserSession.shared.institution?.baseURL)!))

        self.exerciseId = exercise.id
        self.courseId = course.id
    }

    public init(courseId: Int, exerciseId: Int) {
        self._exercise = State(wrappedValue: .loading)
        self._urlRequest = State(wrappedValue: URLRequest(url: URL(string: "/courses/\(courseId)/exercises/\(exerciseId)", relativeTo: UserSession.shared.institution?.baseURL)!))

        self.exerciseId = exerciseId
        self.courseId = courseId
    }

    private var score: String {
        let score = exercise.value?.baseExercise.studentParticipations?
            .first?
            .baseParticipation
            .results?
            .filter { $0.rated ?? false }
            .max(by: { ($0.id ?? Int.min) > ($1.id ?? Int.min) })?
            .score ?? 0

        let maxPoints = exercise.value?.baseExercise.maxPoints ?? 0

        return (score * maxPoints / 100).rounded().clean
    }

    private var showFeedbackButton: Bool {
        switch exercise.value {
        case .fileUpload, .programming, .text:
            return true
        default:
            return false
        }
    }

    private var isExerciseParticipationAvailable: Bool {
        switch exercise.value {
        case .modeling:
            return true
        default:
            return false
        }
    }

    public var body: some View {
        DataStateView(data: $exercise, retryHandler: { await loadExercise() }) { exercise in
            ScrollView {
                VStack(alignment: .leading, spacing: .l) {
                    // All buttons regarding viewing feedback and for the future, starting an exercise
                    HStack(spacing: .m) {
                        if isExerciseParticipationAvailable {
                            if let dueDate = exercise.baseExercise.dueDate {
                                if dueDate > Date() {
                                    if let participationId {
                                        OpenExerciseButton(exercise: exercise, participationId: participationId, problemStatementURL: urlRequest)
                                    } else {
                                        StartExerciseButton(exercise: exercise, participationId: $participationId)
                                    }
                                } else {
                                    if let participationId {
                                        if  latestResultId == nil {
                                            ViewExerciseSubmissionButton(exercise: exercise, participationId: participationId)
                                        } else {
                                            ViewExerciseResultButton(exercise: exercise, participationId: participationId)
                                        }
                                    }
                                }
                            } else {
                                if let participationId {
                                    OpenExerciseButton(exercise: exercise, participationId: participationId, problemStatementURL: urlRequest)
                                } else {
                                    StartExerciseButton(exercise: exercise, participationId: $participationId)
                                }
                            }
                        }
                        if let latestResultId, let participationId, showFeedbackButton {
                            Button {
                                showFeedback = true
                            } label: {
                                Text(R.string.localizable.showFeedback())
                            }
                            .buttonStyle(ArtemisButton())
                            .sheet(isPresented: $showFeedback) {
                                FeedbackView(courseId: courseId,
                                             exerciseId: exerciseId,
                                             participationId: participationId,
                                             resultId: latestResultId)
                            }
                        }
                    }
                    .padding(.horizontal, .m)

                    if !isExerciseParticipationAvailable {
                        ArtemisHintBox(text: R.string.localizable.exerciseParticipationHint(), hintType: .info)
                            .padding(.horizontal, .m)
                    }

                    // All score related information
                    VStack(alignment: .leading, spacing: .xs) {
                        Text(R.string.localizable.points(
                            score,
                            exercise.baseExercise.maxPoints?.clean ?? "0"))
                        .bold()

                        SubmissionResultStatusView(exercise: exercise)
                    }
                    .padding(.horizontal, .m)

                    // Exercise Details
                    VStack(alignment: .leading, spacing: 0) {
                        // Exercise Details title text
                        Text(R.string.localizable.exerciseDetails)
                            .bold()
                            .frame(height: 25, alignment: .center)
                            .padding(.s)

                        Divider()
                            .frame(height: 1.0)
                            .overlay(Color.Artemis.artemisBlue)

                        // Release Date
                        if let releaseDate = exercise.baseExercise.releaseDate {
                            ExerciseDetailCell(descriptionText: R.string.localizable.releaseDate()) {
                                Text(releaseDate.mediumDateShortTime)
                            }
                        }

                        // Due Date
                        if let submissionDate = exercise.baseExercise.dueDate {
                            ExerciseDetailCell(descriptionText: R.string.localizable.submissionDate()) {
                                Text(submissionDate.mediumDateShortTime)
                            }
                        } else {
                            ExerciseDetailCell(descriptionText: R.string.localizable.submissionDate()) {
                                Text(R.string.localizable.noDueDate())
                            }
                        }

                        // Assessment Due Date
                        if let assessmentDate = exercise.baseExercise.assessmentDueDate {
                            ExerciseDetailCell(descriptionText: R.string.localizable.assessmentDate()) {
                                Text(assessmentDate.mediumDateShortTime)
                            }
                        }

                        // Complaints Possible
                        if let complaintPossible = exercise.baseExercise.allowComplaintsForAutomaticAssessments {
                            ExerciseDetailCell(descriptionText: R.string.localizable.complaintPossible()) {
                                Text(complaintPossible ? "Yes" : "No")
                            }
                        }

                        // Exercise Type
                        if exercise.baseExercise.includedInOverallScore != .includedCompletly {
                            ExerciseDetailCell(descriptionText: R.string.localizable.exerciseType()) {
                                Chip(text: exercise.baseExercise.includedInOverallScore.description, backgroundColor: exercise.baseExercise.includedInOverallScore.color, padding: .s)
                            }
                        }

                        // Difficulty
                        if let difficulty = exercise.baseExercise.difficulty {
                            ExerciseDetailCell(descriptionText: R.string.localizable.difficulty()) {
                                Chip(text: difficulty.description, backgroundColor: difficulty.color, padding: .s)
                            }
                        }

                        // Categories
                        if let categories = exercise.baseExercise.categories {
                            ExerciseDetailCell(descriptionText: R.string.localizable.categories()) {
                                ForEach(categories, id: \.category) { category in
                                    Chip(text: category.category, backgroundColor: UIColor(hexString: category.colorCode).suColor, padding: .s)
                                }
                            }
                        }
                    }
                    .background {
                        RoundedRectangle(cornerRadius: 3.0)
                            .stroke(Color.Artemis.artemisBlue, lineWidth: 1.0)
                    }
                    .padding(.horizontal, .m)

                    ArtemisWebView(urlRequest: $urlRequest,
                                   contentHeight: $webViewHeight,
                                   isLoading: $isWebViewLoading)
                    .frame(height: webViewHeight)
                    .loadingIndicator(isLoading: $isWebViewLoading)
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: .l) {
                        exercise.image
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(Color.Artemis.primaryLabel)
                            .frame(width: .smallImage)
                        Text(exercise.baseExercise.title ?? "")
                            .font(.headline)
                    }
                }
            }
        }
        .task {
            await loadExercise()
        }
        .refreshable {
            await refreshExercise()
        }
    }

    private func loadExercise() async {
        if let exercise = exercise.value {
            setParticipationAndResultId(from: exercise)
        } else {
            await refreshExercise()
        }
    }

    private func refreshExercise() async {
        self.exercise = await ExerciseServiceFactory.shared.getExercise(exerciseId: exerciseId)
        if let exercise = self.exercise.value {
            setParticipationAndResultId(from: exercise)
        }
    }

    private func setParticipationAndResultId(from exercise: Exercise) {
        isWebViewLoading = true

        let participation = exercise.getSpecificStudentParticipation(testRun: false)
        participationId = participation?.id
        // Sort participation results by completionDate desc.
        // The latest result is the first rated result in the sorted array (=newest)
        if let latestResultId = participation?.results?.max(by: { $0.completionDate ?? .distantPast > $1.completionDate ?? .distantPast })?.id {
            self.latestResultId = latestResultId
        }

        urlRequest = URLRequest(url: URL(string: "/courses/\(courseId)/exercises/\(exercise.id)/problem-statement/\(participationId?.description ?? "")", relativeTo: UserSession.shared.institution?.baseURL)!)
    }
}

private struct ExerciseDetailCell<Content: View>: View {
    let descriptionText: String
    @ViewBuilder let content: Content

    var body: some View {
        HStack {
            Text(descriptionText)
            Spacer()
            content
        }
        .frame(height: 25, alignment: .center)
        .padding(.s)
    }
}

private struct StartExerciseButton: View {
    var exercise: Exercise
    @Binding var participationId: Int?

    var body: some View {
        Button {
            Task {
                let exerciseService = ExerciseSubmissionServiceFactory.service(for: exercise)
                do {
                    let response = try await exerciseService.startParticipation(exerciseId: exercise.id)
                    participationId = response.baseParticipation.id
                } catch {
                    log.error(String(describing: error))
                }
            }
        } label: {
            Text(R.string.localizable.startExercise())
        }
        .buttonStyle(ArtemisButton())
    }
}

private struct OpenExerciseButton: View {
    var exercise: Exercise
    var participationId: Int
    var problemStatementURL: URLRequest

    var body: some View {
        switch exercise {
        case .modeling:
            NavigationLink(destination: EditModelingExerciseView(exercise: exercise,
                                                                 participationId: participationId,
                                                                 problemStatementURL: problemStatementURL)) {
                Text(R.string.localizable.openModelingEditor())
            }.buttonStyle(ArtemisButton())
        default:
            ArtemisHintBox(text: R.string.localizable.exerciseParticipationHint(), hintType: .info)
        }
    }
}

private struct ViewExerciseSubmissionButton: View {
    var exercise: Exercise
    var participationId: Int

    var body: some View {
        switch exercise {
        case .modeling:
            NavigationLink(destination: ViewModelingExerciseView(exercise: exercise,
                                                                 participationId: participationId)) {
                Text(R.string.localizable.viewSubmission())
            }.buttonStyle(ArtemisButton())
        default:
            ArtemisHintBox(text: R.string.localizable.exerciseParticipationHint(), hintType: .info)
        }
    }
}

private struct ViewExerciseResultButton: View {
    var exercise: Exercise
    var participationId: Int

    var body: some View {
        switch exercise {
        case .modeling:
            NavigationLink(destination: ViewModelingExerciseResultView(exercise: exercise,
                                                                       participationId: participationId)) {
                Text(R.string.localizable.viewResult())
            }.buttonStyle(ArtemisButton())
        default:
            ArtemisHintBox(text: R.string.localizable.exerciseParticipationHint(), hintType: .info)
        }
    }
}

private struct FeedbackView: View {
    @Environment(\.dismiss) var dismiss
    @State private var webViewHeight = CGFloat.s
    @State private var urlRequest: URLRequest
    @State private var isWebViewLoading = true

    init(courseId: Int, exerciseId: Int, participationId: Int, resultId: Int) {
        self._urlRequest = State(wrappedValue: URLRequest(url: URL(string: "/courses/\(courseId)/exercises/\(exerciseId)/participations/\(participationId)/results/\(resultId)/feedback/", relativeTo: UserSession.shared.institution?.baseURL)!))
    }

    var body: some View {
        NavigationView {
            ArtemisWebView(urlRequest: $urlRequest, isLoading: $isWebViewLoading)
                .loadingIndicator(isLoading: $isWebViewLoading)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(R.string.localizable.close()) {
                            dismiss()
                        }
                    }
                }
        }
    }
}
