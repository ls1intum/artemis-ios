//
//  AskIrisButton.swift
//  ArtemisKit
//
//  Created by Senan Aslan on 20.06.26.
//

import Common
import DesignLibrary
import Navigation
import SharedModels
import SwiftUI
import UserStore

/// Opens — creating it if needed — the Iris chat session scoped to a specific
/// lecture or exercise and navigates to it in the course's Iris tab.
///
/// Callers gate on Iris being enabled in the course; for an exercise type Iris has
/// no chat mode for, the button renders nothing.
/// If the user hasn't opted into AI yet, tapping routes to the Iris tab so they
/// can choose there instead of creating a session.
public struct AskIrisButton: View {
    @EnvironmentObject private var navigationController: NavigationController

    private let courseId: Int
    /// `nil` for an exercise type Iris has no chat mode for.
    private let context: SessionContext?
    /// Applied inside the button, so an absent button leaves no padded gap behind.
    private let horizontalPadding: CGFloat

    private let httpService: IrisChatHttpService = IrisChatHttpServiceFactory.shared

    @State private var isLoading = false
    @State private var error: UserFacingError?

    private init(courseId: Int, context: SessionContext?, horizontalPadding: CGFloat) {
        self.courseId = courseId
        self.context = context
        self.horizontalPadding = horizontalPadding
    }

    public var body: some View {
        if let context {
            Button {
                openSession(context: context)
            } label: {
                HStack(spacing: .s) {
                    Group {
                        if isLoading {
                            ProgressView()
                        } else {
                            Image(systemName: "eyes")
                        }
                    }
                    Text(R.string.localizable.askIris())
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(ArtemisButton(priority: .secondary))
            .background(
                // Matches the exercise overview chips.
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.Artemis.artemisBlue.opacity(0.1))
            )
            .disabled(isLoading)
            .padding(.horizontal, horizontalPadding)
            .alert(isPresented: showError, error: error) {}
        }
    }

    /// Whether the user has opted into cloud or local AI; same source as ``IrisSessionListView``.
    private var isAIEnabled: Bool {
        UserSessionFactory.shared.user?.selectedLLMUsage?.isAIEnabled ?? false
    }

    private func openSession(context: SessionContext) {
        // Without consent, send the user to the Iris tab to choose their AI
        // experience rather than creating a session they can't use yet.
        guard isAIEnabled else {
            navigationController.goToIris(courseId: courseId)
            return
        }

        isLoading = true
        Task { @MainActor in
            let result = await httpService.getCurrentOrCreateSession(
                mode: context.mode, entityId: context.entityId)
            isLoading = false
            switch result {
            case .done(let session):
                // Carry this lecture/exercise on the path so the chat pre-selects it
                // (chip + next message), even if the server session has no context yet.
                navigationController.goToIrisSession(courseId: courseId,
                                                     sessionId: session.id,
                                                     contextSource: context.contextSource)
            case .failure(let error):
                self.error = error
            case .loading:
                break
            }
        }
    }

    private var showError: Binding<Bool> {
        Binding(get: { error != nil }, set: { newValue in
            if !newValue {
                error = nil
            }
        })
    }
}

public extension AskIrisButton {
    /// A button for a lecture's Iris chat. Callers gate on Iris being enabled in the course.
    init(courseId: Int, lecture: Lecture, horizontalPadding: CGFloat = 0) {
        self.init(courseId: courseId,
                  context: SessionContext(lecture: lecture),
                  horizontalPadding: horizontalPadding)
    }

    /// A button for an exercise's Iris chat. Renders nothing when the exercise type has no
    /// Iris chat mode (only text & programming do). Callers gate on Iris being enabled.
    init(courseId: Int, exercise: Exercise, horizontalPadding: CGFloat = 0) {
        let context = exercise.irisChatMode.map {
            SessionContext(mode: $0, entityId: exercise.id, entityName: exercise.baseExercise.title)
        }
        self.init(courseId: courseId, context: context, horizontalPadding: horizontalPadding)
    }
}
