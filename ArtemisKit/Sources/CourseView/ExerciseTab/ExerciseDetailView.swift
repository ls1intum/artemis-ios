//
//  ExerciseDetailView.swift
//
//
//  Created by Sven Andabaka on 23.03.23.
//

import Common
import DesignLibrary
import Iris
import Navigation
import SharedModels
import SwiftUI
import Quiz

public struct ExerciseDetailView: View {
    @Environment(\.availableTabs) private var tabs
    @EnvironmentObject var navigationController: NavigationController

    @State private var viewModel: ExerciseDetailViewModel

    public var body: some View {
        DataStateView(data: $viewModel.exercise) {
            await viewModel.loadExercise()
        } content: { exercise in
            ScrollView {
                VStack(alignment: .leading, spacing: .l) {
                    hint
                    ExerciseOverviewChipsRow(exercise: exercise, score: viewModel.score)
                    if tabs.iris {
                        AskIrisButton(courseId: viewModel.courseId, exercise: exercise, horizontalPadding: .m)
                    }
                    if case .quiz(let quiz) = exercise,
                       quiz.canStartLiveQuiz || quiz.canResumeQuiz || quiz.canStartPractice {
                        Button {
                            viewModel.showQuizParticipation = true
                        } label: {
                            if quiz.canStartLiveQuiz {
                                Label(R.string.localizable.startExercise(), systemImage: "play.fill")
                            } else if quiz.canResumeQuiz {
                                Label(R.string.localizable.openExercise(), systemImage: "play.fill")
                            } else {
                                Label(R.string.localizable.startPractice(), systemImage: "memories")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .font(.title2)
                        .padding(.m)
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
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
            .overlay(alignment: .bottomTrailing) {
                feedback(exercise: exercise)
                    .padding()
            }
            .sheet(isPresented: $viewModel.showQuizParticipation) {
                Task {
                    await viewModel.refreshExercise()
                }
            } content: {
                if case .quiz(let quiz) = exercise {
                    QuizParticipationView(exercise: quiz, courseId: viewModel.courseId)
                }
            }
        }
        .task {
            await viewModel.loadExercise()
            await viewModel.loadReviewMetadata()
            await viewModel.loadAssociatedChannel()
        }
        .refreshable {
            await viewModel.refreshExercise()
            await viewModel.loadReviewMetadata()
        }
        .environment(\.resultScorePrecision, viewModel.scorePrecision)
        .navigationBarTitleDisplayMode(.inline)
    }
}

public extension ExerciseDetailView {
    init(course: CourseForOverviewDTO, exercise: Exercise) {
        self.init(viewModel: ExerciseDetailViewModel(
            courseId: course.id,
            exerciseId: exercise.id,
            exercise: .done(response: exercise)))
    }

    init(courseId: Int, exerciseId: Int) {
        self.init(viewModel: ExerciseDetailViewModel(
            courseId: courseId,
            exerciseId: exerciseId,
            exercise: .loading))
    }
}

private extension ExerciseDetailView {
    // All buttons regarding viewing feedback and for the future, starting an exercise
    func feedback(exercise: Exercise) -> some View {
        HStack(spacing: .m) {
            let references = viewModel.reviewReferences
            if !references.isEmpty, viewModel.isFeedbackButtonVisible {
                NavigationLink {
                    ResultReviewPage(references: references)
                } label: {
                    Text(ReviewCopy.text("review.title"))
                }
                .buttonStyle(ArtemisButton())
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
    @ViewBuilder
    func detail(exercise: Exercise) -> some View {
        // Communication
        if let channel = viewModel.channel.value {
            HStack {
                Text(R.string.localizable.communication() + ":")
                    .bold()
                Spacer()
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
            .padding(.m)
            .background(Color(uiColor: .secondarySystemBackground), in: .rect(cornerRadius: .m))
            .padding(.horizontal, .m)
        }
    }

    var problem: some View {
        ProblemStatementView(viewModel: viewModel)
    }
}
