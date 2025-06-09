//
//  ExerciseDetailView.swift
//
//
//  Created by Sven Andabaka on 23.03.23.
//

import Common
import DesignLibrary
import Navigation
import SharedModels
import SwiftUI
import UserStore

public struct ExerciseDetailView: View {
    @EnvironmentObject var navigationController: NavigationController

    @State private var viewModel: ExerciseDetailViewModel

    public var body: some View {
        DataStateView(data: $viewModel.exercise) {
            await viewModel.loadExercise()
        } content: { exercise in
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(alignment: .leading, spacing: .l) {
                        hint
                        ExerciseOverviewChipsRow(exercise: exercise, score: viewModel.score)
                        problem
                        detail(exercise: exercise)
                    }
                    .padding(.bottom, 88)
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

                feedback(exercise: exercise)
                    .padding(.l)
            }
        }
        .task {
            await viewModel.loadExercise()
            await viewModel.loadAssociatedChannel()
        }
        .refreshable {
            await viewModel.refreshExercise()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

public extension ExerciseDetailView {
    init(course: Course, exercise: Exercise) {
        self.init(viewModel: ExerciseDetailViewModel(
            courseId: course.id,
            exerciseId: exercise.id,
            exercise: .done(response: exercise),
            urlRequest: URLRequest(url: URL(
                string: "/courses/\(course.id)/exercises/\(exercise.id)/problem-statement",
                relativeTo: UserSessionFactory.shared.institution?.baseURL)!)))
    }

    init(courseId: Int, exerciseId: Int) {
        self.init(viewModel: ExerciseDetailViewModel(
            courseId: courseId,
            exerciseId: exerciseId,
            exercise: .loading,
            urlRequest: URLRequest(url: URL(
                string: "/courses/\(courseId)/exercises/\(exerciseId)",
                relativeTo: UserSessionFactory.shared.institution?.baseURL)!)))
    }
}

private extension ExerciseDetailView {
    // All buttons regarding viewing feedback and for the future, starting an exercise
    func feedback(exercise: Exercise) -> some View {
        HStack(spacing: .m) {
            if viewModel.isExerciseParticipationAvailable {
                if let dueDate = exercise.baseExercise.dueDate {
                    if dueDate > Date() {
                        if let participationId = viewModel.participationId {
                            OpenExerciseButton(
                                exercise: exercise,
                                participationId: participationId,
                                problemStatementURL: viewModel.urlRequest)
                        } else {
                            StartExerciseButton(exercise: exercise, participationId: $viewModel.participationId)
                        }
                    } else {
                        if let participationId = viewModel.participationId {
                            if viewModel.latestResultId == nil {
                                ViewExerciseSubmissionButton(exercise: exercise, participationId: participationId)
                            } else {
                                ViewExerciseResultButton(exercise: exercise, participationId: participationId)
                            }
                        }
                    }
                } else {
                    if let participationId = viewModel.participationId {
                        OpenExerciseButton(
                            exercise: exercise,
                            participationId: participationId,
                            problemStatementURL: viewModel.urlRequest)
                    } else {
                        StartExerciseButton(exercise: exercise, participationId: $viewModel.participationId)
                    }
                }
            }
            if let latestResultId = viewModel.latestResultId,
               let participationId = viewModel.participationId,
               viewModel.isFeedbackButtonVisible {
                Button {
                    viewModel.isFeedbackPresented = true
                } label: {
                    Text(R.string.localizable.showFeedback())
                }
                .buttonStyle(ArtemisButton())
                .sheet(isPresented: $viewModel.isFeedbackPresented) {
                    FeedbackView(courseId: viewModel.courseId,
                                 exerciseId: viewModel.exerciseId,
                                 participationId: participationId,
                                 resultId: latestResultId)
                }
            }
        }
        .padding(.horizontal, .m)
    }

    @ViewBuilder var hint: some View {
        if !viewModel.isExerciseParticipationAvailable {
            ArtemisHintBox(text: R.string.localizable.exerciseParticipationHint(), hintType: .info)
                .padding(.horizontal, .m)
        }
    }

    // Exercise Details
    func detail(exercise: Exercise) -> some View {
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

            // Communication
            if let channel = viewModel.channel.value {
                Divider()
                    .frame(height: 1.0)
                    .overlay(Color.Artemis.artemisBlue)

                ExerciseDetailCell(descriptionText: R.string.localizable.communication() + ":") {
                    Button {
                        navigationController.outerPath = NavigationPath()
                        navigationController.tabPath.append(
                            ConversationPath(conversation: .channel(conversation: channel),
                                             coursePath: .init(id: viewModel.courseId))
                        )
                    } label: {
                        let name = channel.conversationName
                        let displayName = name
                            .suffix(name.starts(with: "exercise-") ? name.count - 9 : name.count)
                        Text("\(String(displayName)) \(Image(systemName: "chevron.forward"))")
                    }
                }
            }
        }
        .background {
            RoundedRectangle(cornerRadius: 3.0)
                .stroke(Color.Artemis.artemisBlue, lineWidth: 1.0)
        }
        .padding(.horizontal, .m)
    }

    var problem: some View {
        VStack(alignment: .leading, spacing: .s) {
            if case .programming = viewModel.exercise.value {
                Text(R.string.localizable.problemStatement())
                    .font(.headline)
                    .padding(.s)
            }

            if case .quiz = viewModel.exercise.value {
                EmptyView() // explicitly do nothing
            } else {
                ArtemisWebView(
                    urlRequest: $viewModel.urlRequest,
                    contentHeight: $viewModel.webViewHeight,
                    isLoading: $viewModel.isWebViewLoading,
                    customJSHeightQuery: viewModel.webViewHeightJS
                )
                .frame(height: viewModel.webViewHeight)
                .allowsHitTesting(false)
                .loadingIndicator(isLoading: $viewModel.isWebViewLoading)
                .id(viewModel.webViewId)
            }
        }
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
            NavigationLink(R.string.localizable.openModelingEditor()) {
                EditModelingExerciseView(
                    exercise: exercise,
                    participationId: participationId,
                    problemStatementURL: problemStatementURL)
            }
            .buttonStyle(ArtemisButton())
        case .text:
            NavigationLink(R.string.localizable.openExercise()) {
                EditTextExerciseView(
                    exercise: exercise,
                    participationId: participationId,
                    problem: problemStatementURL)
            }
            .buttonStyle(ArtemisButton())
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
            NavigationLink {
                ViewModelingExerciseView(exercise: exercise, participationId: participationId)
            } label: {
                Text(R.string.localizable.viewSubmission())
            }
            .buttonStyle(ArtemisButton())
        case .text:
            NavigationLink {
                ViewTextExerciseView(exercise: exercise, participationId: participationId)
            } label: {
                Text(R.string.localizable.viewSubmission())
            }
            .buttonStyle(ArtemisButton())
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
            NavigationLink {
                ViewModelingExerciseResultView(
                    exercise: exercise,
                    participationId: participationId)
            } label: {
                Text(R.string.localizable.viewResult())
            }
            .buttonStyle(ArtemisButton())
        case .text:
            NavigationLink {
                ViewTextExerciseView(exercise: exercise, participationId: participationId)
            } label: {
                Text(R.string.localizable.viewSubmission())
            }
            .buttonStyle(ArtemisButton())
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
        self._urlRequest = State(wrappedValue: URLRequest(url: URL(
            string: "/courses/\(courseId)/exercises/\(exerciseId)/participations/\(participationId)/results/\(resultId)/feedback/",
            relativeTo: UserSessionFactory.shared.institution?.baseURL)!))
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
