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
        
        return (score * maxPoints / 100).clean
    }
    
    private var showFeedbackButton: Bool {
        switch exercise.value {
        case .fileUpload, .modeling, .programming, .text:
            return true
        default:
            return false
        }
    }
    
    public var body: some View {
        DataStateView(data: $exercise, retryHandler: { await loadExercise() }) { exercise in
            ScrollView {
                VStack(alignment: .leading, spacing: .m) {
                    VStack(alignment: .leading, spacing: .m) {
                        ForEach(exercise.baseExercise.categories ?? [], id: \.category) { category in
                            Chip(text: category.category, backgroundColor: UIColor(hexString: category.colorCode).suColor)
                        }
                        if let dueDate = exercise.baseExercise.dueDate {
                            Text(R.string.localizable.dueDate(dueDate.relative ?? "?"))
                        } else {
                            Text(R.string.localizable.noDueDate())
                        }
                        HStack {
                            Text(R.string.localizable.points(
                                score,
                                exercise.baseExercise.maxPoints?.clean ?? "0"))
                            if exercise.baseExercise.includedInOverallScore != .includedCompletly {
                                Chip(text: exercise.baseExercise.includedInOverallScore.description, backgroundColor: exercise.baseExercise.includedInOverallScore.color)
                            }
                            if let assessmentType = exercise.baseExercise.assessmentType?.description {
                                Text(R.string.localizable.assessment(assessmentType))
                            }
                        }
                        SubmissionResultStatusView(exercise: exercise)
                        if let latestResultId,
                           let participationId,
                           showFeedbackButton {
                            Button(R.string.localizable.showFeedback()) {
                                showFeedback = true
                            }
                            .buttonStyle(ArtemisButton())
                            .sheet(isPresented: $showFeedback) {
                                FeedbackView(courseId: courseId,
                                             exerciseId: exerciseId,
                                             participationId: participationId,
                                             resultId: latestResultId)
                            }
                        }
                        if let participationId {
                            StartExerciseParticipationButton(exercise: exercise, participationId: participationId)
                        }
                    }
                    .padding(.horizontal, .l)
                    
                    ArtemisWebView(urlRequest: $urlRequest,
                                   contentHeight: $webViewHeight,
                                   isLoading: $isWebViewLoading)
                    .frame(height: webViewHeight)
                    .loadingIndicator(isLoading: $isWebViewLoading)
                    Spacer()
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
    }
    
    private func loadExercise() async {
        if let exercise = exercise.value {
            setParticipationAndResultId(from: exercise)
        } else {
            self.exercise = await ExerciseServiceFactory.shared.getExercise(exerciseId: exerciseId)
            if let exercise = self.exercise.value {
                setParticipationAndResultId(from: exercise)
            }
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

private struct StartExerciseParticipationButton: View {
    private var exercise: Exercise
    private var participationId: Int
    
    init(exercise: Exercise, participationId: Int) {
        self.exercise = exercise
        self.participationId = participationId
    }
    
    var body: some View {
        switch exercise {
        case .modeling:
            NavigationLink(destination: ModelingExerciseView(exercise: exercise, participationId: participationId)) {
                Text(R.string.localizable.openModelingEditor())
            }.buttonStyle(ArtemisButton())
        default:
            ArtemisHintBox(text: R.string.localizable.exerciseParticipationHint(), hintType: .info)
        }
    }
}
