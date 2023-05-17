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

public struct ExerciseDetailView: View {

    @State private var webViewHeight = CGFloat.s
    @State private var urlRequest: URLRequest
    @State private var isWebViewLoading = true

    @State private var exercise: DataState<Exercise>

    @State private var showFeedback = false

    private let exerciseId: Int
    private let courseId: Int

    private var latestResultId: Int?
    private var participationId: Int?

    public init(course: Course, exercise: Exercise) {
        let participation = exercise.getSpecificStudentParticipation(testRun: false)
        // Sort participation results by completionDate desc.
        // The latest result is the first rated result in the sorted array (=newest)
        let participationId: String
        if let participation {
            participationId = participation.id.description
            self.participationId = participation.id
        } else {
            participationId = ""
        }

        if let latestResultId = participation?.results?.max(by: { $0.completionDate ?? .distantPast > $1.completionDate ?? .distantPast })?.id {
            self.latestResultId = latestResultId
        }

        self._exercise = State(wrappedValue: .done(response: exercise))
        self._urlRequest = State(wrappedValue: URLRequest(url: URL(string: "/courses/\(course.id)/exercises/\(exercise.id)/problem-statement/\(participationId)", relativeTo: UserSession.shared.institution?.baseURL)!))

        self.exerciseId = exercise.id
        self.courseId = course.id
    }

    public init(courseId: Int, exerciseId: Int) {
        self._exercise = State(wrappedValue: .loading)
        // TODO: show result in webview after loaded exercise
        self._urlRequest = State(wrappedValue: URLRequest(url: URL(string: "/courses/\(courseId)/exercises/\(exerciseId)", relativeTo: UserSession.shared.institution?.baseURL)!))
        self.exerciseId = exerciseId
        self.courseId = courseId
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
                            Text("Due Date: \(dueDate.relative ?? "?")")
                        } else {
                            Text("No due date")
                        }
                        HStack {
                            Text("Points: \(exercise.baseExercise.studentParticipations?.first?.baseParticipation.submissions?.first?.baseSubmission.results?.first?.score?.clean ?? "0") of \(exercise.baseExercise.maxPoints?.clean ?? "0")")
                            if exercise.baseExercise.includedInOverallScore != .includedCompletly {
                                Chip(text: exercise.baseExercise.includedInOverallScore.description, backgroundColor: exercise.baseExercise.includedInOverallScore.color)
                            }
                            Text("Assessment: \(exercise.baseExercise.assessmentType?.description ?? "Unknown")")
                        }
                        SubmissionResultStatusView(exercise: exercise)
                        if let latestResultId, let participationId {
                            Button("Show Feedback") {
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
                    }
                    .padding(.horizontal, .l)

                    ArtemisWebView(urlRequest: $urlRequest,
                                   contentHeight: $webViewHeight,
                                   isLoading: $isWebViewLoading)
                        .frame(height: webViewHeight)
                        .disabled(true)
                        .loadingIndicator(isLoading: $isWebViewLoading)
                    Spacer()
                }
            }
            .navigationTitle(exercise.baseExercise.title ?? "Unknown")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: .l) {
                        exercise.image
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(Color.Artemis.primaryLabel)
                            .frame(width: .smallImage)
                        Text(exercise.baseExercise.title ?? "Unknown")
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
        if exercise.value == nil {
            self.exercise = await ExerciseServiceFactory.shared.getExercise(exerciseId: exerciseId)
        }
    }
}

private struct FeedbackView: View {

    @State private var webViewHeight = CGFloat.s
    @State private var urlRequest: URLRequest
    @State private var isWebViewLoading = true

    init(courseId: Int, exerciseId: Int, participationId: Int, resultId: Int) {
        self._urlRequest = State(wrappedValue: URLRequest(url: URL(string: "/courses/\(courseId)/exercises/\(exerciseId)/participations/\(participationId)/results/\(resultId)/feedback/", relativeTo: UserSession.shared.institution?.baseURL)!))
    }

    var body: some View {
        // TODO: add close button
        ArtemisWebView(urlRequest: $urlRequest, isLoading: $isWebViewLoading)
            .loadingIndicator(isLoading: $isWebViewLoading)
    }
}
