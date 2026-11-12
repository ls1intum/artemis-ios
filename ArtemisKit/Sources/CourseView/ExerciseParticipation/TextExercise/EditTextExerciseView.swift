import ArtemisMarkdown
import DesignLibrary
import SwiftUI
import UIKit
import UserStore

struct EditTextExerciseView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject private var userSession = UserSessionFactory.shared
    @State var viewModel: EditTextExerciseViewModel
    @FocusState private var answerFocused: Bool

    var body: some View {
        GeometryReader { geometry in
            let compactKeyboard = answerFocused && geometry.size.height < 260
            Group {
                if geometry.size.width >= 800, !dynamicTypeSize.isAccessibilitySize {
                    HStack(spacing: 0) {
                        assignment
                            .frame(width: min(geometry.size.width * 0.4, 440))
                        Divider()
                        editor(compactKeyboard: compactKeyboard)
                    }
                } else {
                    editor(compactKeyboard: compactKeyboard)
                }
            }
            .toolbar {
                if compactKeyboard {
                    ToolbarItem(placement: .primaryAction) { submitButton }
                }
            }
        }
        .navigationTitle(viewModel.context?.exercise.title ?? R.string.localizable.textExerciseAnswer())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink {
                    assignment
                        .navigationTitle(R.string.localizable.textExerciseAssignment())
                        .navigationBarTitleDisplayMode(.inline)
                } label: {
                    Label(R.string.localizable.textExerciseAssignment(), systemImage: "doc.text")
                }
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button {
                    answerFocused = false
                } label: {
                    Image(systemName: "keyboard.chevron.compact.down")
                }
                .accessibilityLabel(R.string.localizable.close())
            }
        }
        .task { await viewModel.load() }
        .onReceive(userSession.objectWillChange) {
            Task { @MainActor in
                await Task.yield()
                viewModel.validateSession()
            }
        }
        .onChange(of: viewModel.canEdit) {
            if !viewModel.canEdit { answerFocused = false }
        }
        .onChange(of: scenePhase) {
            viewModel.validateSession()
        }
    }

    private func editor(compactKeyboard: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if !compactKeyboard {
                VStack(alignment: .leading, spacing: 8) {
                    Text(R.string.localizable.textExerciseAnswer()).font(.headline)
                    status
                    messages
                }
                .padding()
                Divider()
            }
            TextEditor(text: Binding(get: { viewModel.text }, set: viewModel.updateText))
                .font(.body)
                .padding(.horizontal, 10)
                .focused($answerFocused)
                .disabled(!viewModel.canEdit)
                .accessibilityLabel(R.string.localizable.textExerciseAnswer())
                .accessibilityIdentifier("textExerciseAnswer")
                .overlay {
                    if viewModel.isLoading && !viewModel.canEdit { ProgressView() }
                }
            if !compactKeyboard {
                Divider()
                footer
            }
        }
        .background(Color(uiColor: .systemBackground))
    }

    @ViewBuilder private var status: some View {
        if viewModel.isSubmitting {
            ProgressView(R.string.localizable.submitSubmission())
        } else if !viewModel.hasUnsubmittedChanges, viewModel.submission?.submitted == true {
            Label(R.string.localizable.textExerciseSubmitted(), systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        } else if viewModel.isDraftSaved {
            Label(R.string.localizable.textExerciseLocalDraft(), systemImage: "internaldrive")
                .foregroundStyle(.secondary)
        } else if viewModel.canEdit {
            Label(R.string.localizable.textExerciseSavingDraft(), systemImage: "internaldrive")
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder private var messages: some View {
        if let error = viewModel.errorMessage {
            Text(error).font(.callout).foregroundStyle(.red)
            if viewModel.context == nil {
                Button(R.string.localizable.textExerciseRetry()) { Task { await viewModel.load() } }
                    .disabled(viewModel.isLoading)
            }
        }
        if let error = viewModel.draftError {
            Text(error).font(.callout).foregroundStyle(.red)
            if viewModel.canEdit {
                Button(R.string.localizable.textExerciseSaveAgain(), action: viewModel.retryDraftSave)
            } else {
                Button(R.string.localizable.textExerciseRetry()) { Task { await viewModel.load() } }
            }
        }
        if viewModel.hasConflict {
            NavigationLink {
                conflict
            } label: {
                Label(R.string.localizable.textExerciseConflict(), systemImage: "exclamationmark.arrow.triangle.2.circlepath")
                    .font(.callout)
            }
        } else if viewModel.isOverLimit {
            Text(R.string.localizable.textExerciseLimit()).font(.callout).foregroundStyle(.red)
        } else if let context = viewModel.context, !context.isSubmissionOpen(at: .now) {
            Text(R.string.localizable.textExerciseClosed()).font(.callout).foregroundStyle(.secondary)
        } else if viewModel.hasUnsubmittedChanges, viewModel.submittedText != nil {
            Text(R.string.localizable.textExerciseSubmittedWithDraft()).font(.callout).foregroundStyle(.secondary)
        }
    }

    private var footer: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 16) {
                copyButton
                Spacer(minLength: 8)
                counter
                submitButton
            }
            VStack(alignment: .leading, spacing: 8) {
                counter
                HStack {
                    copyButton
                    Spacer(minLength: 8)
                    submitButton
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private var copyButton: some View {
        Button {
            UIPasteboard.general.string = viewModel.text
        } label: {
            Label(R.string.localizable.textExerciseCopyAnswer(), systemImage: "doc.on.doc")
        }
        .labelStyle(.iconOnly)
        .frame(minWidth: 44, minHeight: 44)
        .disabled(viewModel.text.isEmpty)
    }

    private var counter: some View {
        Text("\(viewModel.characterCount.formatted()) / 30,000")
            .font(.caption.monospacedDigit())
            .foregroundStyle(viewModel.isOverLimit ? .red : .secondary)
            .accessibilityLabel("\(viewModel.characterCount) / 30000")
    }

    private var submitButton: some View {
        TimelineView(.periodic(from: .now, by: 1)) { _ in
            Button {
                answerFocused = false
                Task { await viewModel.submit() }
            } label: {
                Label(R.string.localizable.submitSubmission(), systemImage: "paperplane.fill")
                    .frame(minHeight: 32)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.canSubmit)
            .accessibilityIdentifier("textExerciseSubmit")
        }
    }

    private var assignment: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(R.string.localizable.textExerciseAssignment()).font(.title2.bold())
                if let statement = viewModel.context?.exercise.problemStatement, !statement.isEmpty {
                    ArtemisMarkdownView(string: statement)
                } else {
                    Text(R.string.localizable.textExerciseNoAssignment()).foregroundStyle(.secondary)
                }
                Text(R.string.localizable.textExerciseDraftExplanation()).font(.callout).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .background(Color(uiColor: .secondarySystemBackground))
    }

    private var conflict: some View {
        TextExerciseConflictView(viewModel: viewModel)
    }
}

private struct TextExerciseConflictView: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: EditTextExerciseViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(R.string.localizable.textExerciseConflictExplanation())
                Text(R.string.localizable.textExerciseServerAnswer()).font(.headline)
                Text(viewModel.latestServerText).textSelection(.enabled)
                Divider()
                Text(R.string.localizable.textExerciseAnswer()).font(.headline)
                Text(viewModel.text).textSelection(.enabled)
                Button(R.string.localizable.textExerciseKeepDraft()) {
                    viewModel.keepDraft()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                Button(R.string.localizable.textExerciseUseServer()) {
                    viewModel.useServerAnswer()
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
        .navigationTitle(R.string.localizable.textExerciseConflict())
        .navigationBarTitleDisplayMode(.inline)
    }
}
