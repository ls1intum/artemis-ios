//
//  IrisChatViewModel.swift
//  ArtemisKit
//
//  Created by Senan Aslan on 25.05.26.
//

import Common
import Foundation
import Navigation
import SwiftUI

@MainActor
@Observable
final class IrisChatViewModel {
    let sessionPath: IrisSessionPath
    private let httpService: IrisChatHttpService
    private var websocketTask: Task<Void, Never>?

    var messages: DataState<[IrisMessageResponseDTO]> = .loading
    var stages: [IrisStageDTO] = []
    var sessionTitle: String?
    var suggestions: [String] = []
    var rateLimitInfo: IrisRateLimitInformation?
    var inputText = ""

    /// The context the server currently associates with this session. Seeded
    /// from the session DTO and advanced to `pendingContext` after each
    /// successful send that carried one.
    private(set) var committedContext: SessionContext?

    /// A not-yet-sent context override chosen via the "+" sheet. `nil` means the
    /// next message keeps the committed context.
    private(set) var pendingContext: SessionContext?

    /// Pending wins over committed for display and for the next send.
    var effectiveSelection: SessionContext? {
        pendingContext ?? committedContext
    }

    /// The selection to render as a chip — only lecture/exercise contexts get
    /// one; the implicit base course chat never shows a chip.
    var displayedChipContext: SessionContext? {
        guard let selection = effectiveSelection else { return nil }
        switch selection.mode {
        case .lecture, .textExercise, .programmingExercise:
            return selection
        default:
            return nil
        }
    }

    /// True while the last known message is the user's — i.e. we sent it but the
    /// reply (which only arrives over the websocket `MESSAGE` payload)
    /// hasn't landed yet. Drives the inline loading indicator.
    var isAwaitingResponse: Bool {
        messages.value?.last?.sender == .user
    }

    /// First non-internal stage that isn't `done`/`skipped`. Covers `inProgress`,
    /// `notStarted` and `error` in one pass (mirrors the Angular client's
    /// `firstUnfinished`). Nil once the pipeline is fully done — the loading
    /// row then falls back to a generic label while the `MESSAGE` frame lands.
    var currentStage: IrisStageDTO? {
        stages.first { !$0.internal && $0.state != .done && $0.state != .skipped }
    }

    var error: UserFacingError?
    var showError: Binding<Bool> {
        Binding(get: {
            self.error != nil
        }, set: { newValue in
            if !newValue {
                self.error = nil
            }
        })
    }

    init(sessionPath: IrisSessionPath,
         session: IrisSessionDTO?,
         httpService: IrisChatHttpService = IrisChatHttpServiceFactory.shared) {
        self.sessionPath = sessionPath
        self.inputText = sessionPath.defaultInput
        self.httpService = httpService
        self.sessionTitle = session?.title
        self.committedContext = session?.context
    }

    func loadMessages() async {
        let result = await httpService.getMessages(sessionId: sessionPath.sessionId)
        switch result {
        case .done(let response):
            messages = .done(response: response)
        case .failure(let error):
            messages = .failure(error: error)
        case .loading:
            messages = .loading
        }
    }

    /// Silent catch-up refresh for returning from the background, where a reply
    /// published over the STOMP topic while we were disconnected is otherwise
    /// lost (topics aren't replayed on reconnect). Unlike `loadMessages`, it
    /// never overwrites loaded messages with a `.loading`/`.failure` state — a
    /// flaky network on resume must not wipe the visible chat. The server list
    /// is authoritative; the live stream dedupes via `upsert`.
    func refreshMessages() async {
        if case .done(let response) = await httpService.getMessages(sessionId: sessionPath.sessionId) {
            messages = .done(response: response)
        }
    }

    func subscribeToWebsocket() async {
        let stream = await IrisWebsocketServiceFactory.shared.subscribe(sessionId: sessionPath.sessionId)
        websocketTask = Task { [weak self] in
            for await dto in stream {
                guard let self else { return }
                handleWebsocketDTO(dto)
            }
        }
    }

    /// Sets the pending context from the sheet's "Set" action.
    func commitPendingSelection(_ context: SessionContext) {
        pendingContext = context
    }

    /// Removes the chip: drops the override and reverts to the base course chat
    /// for the next message.
    func clearPendingSelection() {
        pendingContext = SessionContext(mode: .course, entityId: sessionPath.courseId)
    }

    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let content = [IrisMessageContentDTO.text(text)]

        // Only attach the pending context when it actually differs from what the
        // server already has, so we don't resend the same context every message.
        var pendingContextDTO: IrisPendingContextDTO?
        if let pending = pendingContext, pending != committedContext {
            pendingContextDTO = IrisPendingContextDTO(
                mode: pending.mode,
                entityId: pending.entityId)
        }
        let request = IrisMessageRequestDTO(content: content, pendingContext: pendingContextDTO)

        Task { [weak self] in
            guard let self else { return }
            let result = await httpService.sendMessage(sessionId: sessionPath.sessionId, request: request)
            switch result {
            case .done(let response):
                inputText = ""
                // The send succeeded with `pendingContext`; it is now the
                // session's context, so promote it and clear the override.
                if let pending = pendingContext {
                    committedContext = pending
                    pendingContext = nil
                }
                upsert(message: response)
            case .failure(let error):
                self.error = error
            case .loading:
                break
            }
        }
    }

    func rateMessage(messageId: Int, helpful: Bool) {
        Task { [weak self] in
            guard let self else { return }
            let result = await httpService.rateMessage(
                sessionId: sessionPath.sessionId, messageId: messageId, helpful: helpful)
            switch result {
            case .done(let response):
                upsert(message: response)
            case .failure(let error):
                self.error = error
            case .loading:
                break
            }
        }
    }

    func deleteSession() async -> Bool {
        let result = await httpService.deleteSession(sessionId: sessionPath.sessionId)
        switch result {
        case .success:
            return true
        case .failure(let networkError):
            self.error = UserFacingError(title: networkError.localizedDescription)
            return false
        case .loading, .notStarted:
            return false
        }
    }

    func disconnect() async {
        await IrisWebsocketServiceFactory.shared.unsubscribe(sessionId: sessionPath.sessionId)
        websocketTask?.cancel()
        websocketTask = nil
    }

    private func handleWebsocketDTO(_ dto: IrisChatWebsocketDTO) {
        updateMeta(from: dto)

        switch dto.type {
        case .message:
            guard let message = dto.message else { return }
            upsert(message: message)
        case .status, .unknown:
            break
        }
    }

    /// Replaces an existing message with the same id, or appends if unknown.
    /// A message can arrive both via the HTTP send response and the websocket,
    /// so plain append would duplicate.
    private func upsert(message: IrisMessageResponseDTO) {
        if let id = message.id, let index = messages.value?.firstIndex(where: { $0.id == id }) {
            messages.value?[index] = message
        } else {
            messages.value?.append(message)
        }
    }

    /// Merges only the fields the server actually sent. `STATUS` payloads omit
    /// most fields (see `IrisChatWebsocketDTO`); writing nil would wipe state.
    private func updateMeta(from dto: IrisChatWebsocketDTO) {
        if let stages = dto.stages {
            self.stages = stages
        }
        if let title = dto.sessionTitle {
            sessionTitle = title
        }
        if let suggestions = dto.suggestions {
            self.suggestions = suggestions
        }
        if let rateLimit = dto.rateLimitInfo {
            rateLimitInfo = rateLimit
        }
    }
}
