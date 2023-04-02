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

struct ExerciseDetailView: View {

    @State var webViewHeight = CGFloat.s
    @State var urlRequest: URLRequest

    let course: Course
    let exercise: Exercise

    init(course: Course, exercise: Exercise) {

        self._urlRequest = State(wrappedValue: URLRequest(url: URL(string: "/courses/\(course.id)/exercises/\(exercise.id)", relativeTo: UserSession.shared.institution?.baseURL)!))
        self.course = course
        self.exercise = exercise
    }

    var body: some View {
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
}
