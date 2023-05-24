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

public struct ExerciseDetailView: View {

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
                                exercise.baseExercise.studentParticipations?.first?.baseParticipation.submissions?.first?.baseSubmission.results?.first?.score?.clean ?? "0",
                                exercise.baseExercise.maxPoints?.clean ?? "0"))
                            if exercise.baseExercise.includedInOverallScore != .includedCompletly {
                                Chip(text: exercise.baseExercise.includedInOverallScore.description, backgroundColor: exercise.baseExercise.includedInOverallScore.color)
                            }
                            Text(R.string.localizable.assessment(exercise.baseExercise.assessmentType?.description ?? R.string.localizable.unknown()))
                        }
                        SubmissionResultStatusView(exercise: exercise)
                        if let latestResultId, let participationId {
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
            .navigationTitle(exercise.baseExercise.title ?? R.string.localizable.unknown())
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: .l) {
                        exercise.image
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(Color.Artemis.primaryLabel)
                            .frame(width: .smallImage)
                        Text(exercise.baseExercise.title ?? R.string.localizable.unknown())
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
