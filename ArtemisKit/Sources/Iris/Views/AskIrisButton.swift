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
/// Callers gate on Iris being enabled in the course. The exercise initializer is
/// failable — render it via `if let`, since it returns `nil` for an exercise type
/// Iris has no chat mode for, leaving no gap when absent.
/// If the user hasn't opted into AI yet, tapping routes to the Iris tab so they
/// can choose there instead of creating a session.
public struct AskIrisButton: View {
    @EnvironmentObject private var navigationController: NavigationController

    private let courseId: Int
    private let context: SessionContext

    private let httpService: IrisChatHttpService = IrisChatHttpServiceFactory.shared

    @State private var isLoading = false
    @State private var error: UserFacingError?

    private init(courseId: Int, context: SessionContext) {
        self.courseId = courseId
        self.context = context
    }

    public var body: some View {
        Button(action: openSession) {
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
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.Artemis.artemisBlue.opacity(0.1))
        )
        .disabled(isLoading)
        .alert(isPresented: showError, error: error) {}
    }

    /// Whether the user has opted into cloud or local AI; same source as ``IrisSessionListView``.
    private var isAIEnabled: Bool {
        UserSessionFactory.shared.user?.selectedLLMUsage?.isAIEnabled ?? false
    }

    private func openSession() {
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
                navigationController.goToIrisSession(courseId: courseId, sessionId: session.id, contextSource: context.contextSource)
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
    init(courseId: Int, lecture: Lecture) {
        self.init(courseId: courseId, context: SessionContext(lecture: lecture))
    }

    /// A button for an exercise's Iris chat, or `nil` when the exercise type has no
    /// Iris chat mode (only text & programming do). Callers gate on Iris being enabled.
    init?(courseId: Int, exercise: Exercise) {
        guard let context = SessionContext(exercise: exercise) else { return nil }
        self.init(courseId: courseId, context: context)
    }
}
