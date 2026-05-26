//
//  IrisChatViewModel.swift
//  ArtemisKit
//
//  Created by Senan Aslan on 25.05.26.
//

import Common
import Foundation
import SwiftUI

@MainActor
@Observable
final class IrisChatViewModel {
    let sessionPath: IrisSessionPath
    private let httpService: IrisChatHttpService

    var messages: [IrisMessageResponseDTO] = []
    var stages: [IrisStageDTO] = []
    var sessionTitle: String?
    var suggestions: [String] = []
    var rateLimitInfo: IrisRateLimitInformation?
    var inputText = ""

    var isLoading = false
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

    private var websocketTask: Task<Void, Never>?

    init(sessionPath: IrisSessionPath,
         httpService: IrisChatHttpService = IrisChatHttpServiceFactory.shared) {
        self.sessionPath = sessionPath
        self.httpService = httpService
        self.sessionTitle = sessionPath.session?.title
    }

    func loadMessages() async {
        isLoading = true
        let result = await httpService.getMessages(sessionId: sessionPath.id)
        switch result {
        case .done(let response):
            messages = response
        case .failure(let error):
            self.error = error
        case .loading:
            break
        }
        isLoading = false
    }

    func connectWebSocket() async {
        let stream = await IrisWebsocketServiceFactory.shared.subscribe(sessionId: sessionPath.id)
        websocketTask = Task { [weak self] in
            for await dto in stream {
                guard let self else { return }
                handleWebsocketDTO(dto)
            }
        }
    }

    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let content = [IrisMessageContentDTO.text(text)]
        let request = IrisMessageRequestDTO(content: content)

        inputText = ""

        Task { [weak self] in
            guard let self else { return }
            let result = await httpService.sendMessage(sessionId: sessionPath.id, request: request)
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
        isLoading = true
        let result = await httpService.deleteSession(sessionId: sessionPath.id)
        isLoading = false
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
        await IrisWebsocketServiceFactory.shared.unsubscribe(sessionId: sessionPath.id)
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

    private func upsert(message: IrisMessageResponseDTO) {
        if let id = message.id, let index = messages.firstIndex(where: { $0.id == id }) {
            messages[index] = message
        } else {
            messages.append(message)
        }
    }

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
