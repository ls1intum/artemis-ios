import ReviewContent
import SharedModels
import SwiftUI

struct QuizTraingQuestionsView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: QuizTrainingViewModel

    var body: some View {
        Group {
            switch viewModel.phase {
            case .idle, .loading:
                ProgressView(TrainingCopy.text("loading"))
            case .answering, .submitting, .evaluated, .uncertain:
                if let presentation = viewModel.presentation {
                    QuizQuestionView(question: presentation.question)
                        .id("\(presentation.question.id ?? -1):\(viewModel.hasSubmitted)")
                }
            case .unratedConfirmation:
                status(title: "practice", message: "practice.info", symbol: "book") {
                    Button(TrainingCopy.text("practice.continue")) { viewModel.acceptUnratedPractice() }.buttonStyle(.borderedProminent)
                    finishButton
                }
            case .summary:
                status(title: "summary", message: "summary.info", symbol: "checkmark.circle") {
                    Text(TrainingCopy.count(viewModel.confirmedCount)).font(.title3.bold())
                    LabeledContent(TrainingCopy.text("summary.rated"), value: viewModel.ratedCount.formatted())
                    LabeledContent(TrainingCopy.text("summary.practice"), value: (viewModel.confirmedCount - viewModel.ratedCount).formatted())
                    Button(TrainingCopy.text("continue")) { Task { await viewModel.continueTraining() } }.buttonStyle(.borderedProminent)
                    finishButton
                }
            case .pageFailure:
                status(title: "page.error", message: "page.info", symbol: "wifi.exclamationmark") {
                    Button(TrainingCopy.text("retry")) { Task { await viewModel.retryPage() } }.buttonStyle(.borderedProminent)
                    finishButton
                }
            case .revisionRequired:
                status(title: "revision.title", message: "revision.info", symbol: "arrow.clockwise") {
                    Button(TrainingCopy.text("revision.start")) { Task { await viewModel.startFreshRevision() } }.buttonStyle(.borderedProminent)
                    finishButton
                }
            case .empty:
                status(title: "empty.title", message: "empty.info", symbol: "books.vertical") {
                    Button(TrainingCopy.text("retry")) { Task { await viewModel.startFreshRevision() } }.buttonStyle(.bordered)
                    finishButton
                }
            case .accessLost:
                status(title: "access.title", message: "access.info", symbol: "lock") { EmptyView() }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle(TrainingCopy.text("title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .preference(key: QuizTrainingSessionVisibilityKey.self, value: true)
        .environment(viewModel as QuizViewModel)
        .environment(viewModel)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(TrainingCopy.text("finish")) { viewModel.finish(); dismiss() }
                } label: { Image(systemName: "ellipsis.circle").accessibilityLabel(TrainingCopy.text("actions")) }
                .disabled(viewModel.phase == .submitting)
            }
        }
        .task { await viewModel.loadQuestions() }
        .onAppear { viewModel.validateSession() }
    }
    private var finishButton: some View {
        Button(TrainingCopy.text("finish")) { viewModel.finish(); dismiss() }.buttonStyle(.bordered)
    }
    private func status<Actions: View>(title: String, message: String, symbol: String, @ViewBuilder actions: () -> Actions) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Image(systemName: symbol).font(.largeTitle).foregroundStyle(.tint).accessibilityHidden(true)
                Text(TrainingCopy.text(title)).font(.title2.bold()).accessibilityAddTraits(.isHeader)
                Text(TrainingCopy.text(message)).foregroundStyle(.secondary)
                actions()
            }.frame(maxWidth: 600, alignment: .leading).padding(24).frame(maxWidth: .infinity)
        }
    }
}

struct QuizQuestionView: View {
    @Environment(QuizTrainingViewModel.self) private var viewModel
    let question: DTO.QuizQuestionTraining

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(TrainingCopy.count(viewModel.confirmedCount)).font(.subheadline).foregroundStyle(.secondary)
                    HStack(alignment: .top) {
                        if let title { Text(title).font(.title2.bold()).accessibilityAddTraits(.isHeader).frame(maxWidth: .infinity, alignment: .leading) }
                        if let hint { HintButton(hint: hint) }
                    }
                    Text(TrainingCopy.text(question.isRated == true ? "rated" : "practice")).font(.subheadline).foregroundStyle(.secondary)
                }.padding(.horizontal)
                questionBody
                if viewModel.phase == .uncertain {
                    VStack(alignment: .leading, spacing: 8) {
                        Label(TrainingCopy.text("uncertain.title"), systemImage: "exclamationmark.triangle").font(.headline)
                        Text(TrainingCopy.text("uncertain.info"))
                    }.padding(.horizontal).accessibilityElement(children: .combine)
                }
                if viewModel.hasSubmitted {
                    VStack(alignment: .leading, spacing: 8) {
                        if let score = viewModel.currentScore {
                            Text("\(TrainingCopy.text("score")): \(viewModel.formattedPoints(score.reached)) / \(viewModel.formattedPoints(score.total))").font(.headline).monospacedDigit()
                        } else { Text(TrainingCopy.text("score.unknown")).foregroundStyle(.secondary) }
                        if let explanation = QuizReviewQuestionContent(question.quizQuestionWithSolutionDTO).explanation, !explanation.isEmpty {
                            Text(TrainingCopy.text("explanation")).font(.headline)
                            SafeReviewContent(explanation)
                        }
                    }.padding(.horizontal)
                }
            }.frame(maxWidth: 760, alignment: .leading).padding(.vertical, 20).frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            if viewModel.phase == .uncertain {
                ToolbarItem(placement: .bottomBar) {
                    Button(TrainingCopy.text("uncertain.retry")) { Task { await viewModel.retrySubmission() } }.buttonStyle(.borderedProminent)
                }
            } else if viewModel.hasSubmitted {
                ToolbarItem(placement: .bottomBar) {
                    Button(TrainingCopy.text("next")) { Task { await viewModel.advance() } }.buttonStyle(.borderedProminent)
                }
            }
        }
    }
    @ViewBuilder private var questionBody: some View {
        if !TrainingProjection.canAnswer(question) {
            Text(TrainingCopy.text("unsupported")).padding(.horizontal)
            if viewModel.phase == .answering {
                Button(TrainingCopy.text("skip")) { Task { await viewModel.skip() } }.padding(.horizontal)
            }
        } else {
        switch question.quizQuestionWithSolutionDTO {
        case .multipleChoice(let mc): MCQuestionView(question: question, questionWithAnswer: mc, previousAnswer: viewModel.presentation?.answer)
        case .dragAndDrop(let dnd): DNDQuestionView(question: question, questionWithAnswer: dnd, previousAnswer: viewModel.presentation?.answer)
        case .shortAnswer(let sa):
            if let result = viewModel.presentation?.shortAnswer {
                ShortAnswerResultReview(presentation: .init(question: sa, answer: result))
            } else { ShortAnswerQuestionView(question: question, questionWithSolution: sa, previousAnswer: viewModel.presentation?.answer) }
        }
        }
    }
    private var hint: String? {
        switch question.quizQuestionWithSolutionDTO {
        case .multipleChoice(let value): value.hint
        case .dragAndDrop(let value): value.hint
        case .shortAnswer(let value): value.hint
        }
    }
    private var title: String? {
        switch question.quizQuestionWithSolutionDTO {
        case .multipleChoice(let value): value.title
        case .dragAndDrop(let value): value.title
        case .shortAnswer(let value): value.title
        }
    }
}
