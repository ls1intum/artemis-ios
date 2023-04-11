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

    @State private var exercise: DataState<Exercise>

    private let exerciseId: Int

    public init(course: Course, exercise: Exercise) {
        self._exercise = State(wrappedValue: .done(response: exercise))
        self._urlRequest = State(wrappedValue: URLRequest(url: URL(string: "/courses/\(course.id)/exercises/\(exercise.id)", relativeTo: UserSession.shared.institution?.baseURL)!))
        self.exerciseId = exercise.id
    }

    public init(courseId: Int, exerciseId: Int) {
        self._exercise = State(wrappedValue: .loading)
        self._urlRequest = State(wrappedValue: URLRequest(url: URL(string: "/courses/\(courseId)/exercises/\(exerciseId)", relativeTo: UserSession.shared.institution?.baseURL)!))
        self.exerciseId = exerciseId
    }

    public var body: some View {
        DataStateView(data: $exercise, retryHandler: { await loadExercise() }) { exercise in
            ScrollView {
                VStack(alignment: .leading, spacing: .m) {
                    VStack(alignment: .leading, spacing: .m) {
                        HStack(spacing: .l) {
                            exercise.image
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(Color.Artemis.primaryLabel)
                                .frame(width: .smallImage)
                            Text(exercise.baseExercise.title ?? "Unknown")
                                .font(.title3)
                            Spacer()
                        }
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
                    }
                    .padding(.horizontal, .l)
                    ArtemisWebView(urlRequest: $urlRequest,
                                   contentHeight: $webViewHeight)
                    .frame(height: webViewHeight)
                    .disabled(true)
                    Spacer()
                }
            }
            .navigationTitle(exercise.baseExercise.title ?? "Unknown")
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
