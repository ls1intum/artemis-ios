//
//  IrisChatHttpServiceImpl.swift
//  ArtemisKit
//
//  Created by Senan Aslan on 17.05.26.
//

import APIClient
import Common
import Foundation

struct IrisChatHttpServiceImpl: IrisChatHttpService {

    let client = APIClient()

    // MARK: - Sessions

    struct GetCurrentSessionRequest: APIRequest {
        typealias Response = IrisSession

        let mode: ChatServiceMode
        let entityId: Int

        var method: HTTPMethod { .post }

        var resourceName: String {
            if mode == .tutorSuggestion {
                return "api/iris/tutor-suggestion/posts/\(entityId)/sessions/current"
            }
            return "api/iris/chat/sessions/current"
        }

        var params: [URLQueryItem] {
            guard mode != .tutorSuggestion else { return [] }
            return [
                .init(name: "mode", value: mode.rawValue),
                .init(name: "entityId", value: "\(entityId)")
            ]
        }
    }

    func getCurrentOrCreateSession(mode: ChatServiceMode, entityId: Int) async -> DataState<IrisSession> {
        let result = await client.sendRequest(GetCurrentSessionRequest(mode: mode, entityId: entityId))
        switch result {
        case .success(let response):
            return .done(response: response.0)
        case .failure(let error):
            return .failure(error: UserFacingError(error: error))
        }
    }

    struct CreateSessionRequest: APIRequest {
        typealias Response = IrisSession

        let mode: ChatServiceMode
        let entityId: Int

        var method: HTTPMethod { .post }

        var resourceName: String {
            if mode == .tutorSuggestion {
                return "api/iris/tutor-suggestion/posts/\(entityId)/sessions"
            }
            return "api/iris/chat/sessions"
        }

        var params: [URLQueryItem] {
            guard mode != .tutorSuggestion else { return [] }
            return [
                .init(name: "mode", value: mode.rawValue),
                .init(name: "entityId", value: "\(entityId)")
            ]
        }
    }

    func createSession(mode: ChatServiceMode, entityId: Int) async -> DataState<IrisSession> {
        let result = await client.sendRequest(CreateSessionRequest(mode: mode, entityId: entityId))
        switch result {
        case .success(let response):
            return .done(response: response.0)
        case .failure(let error):
            return .failure(error: UserFacingError(error: error))
        }
    }

    struct GetChatSessionsRequest: APIRequest {
        typealias Response = [IrisSessionDTO]

        let courseId: Int

        var method: HTTPMethod { .get }

        var resourceName: String {
            "api/iris/chat/courses/\(courseId)/sessions/overview"
        }
    }

    func getChatSessions(courseId: Int) async -> DataState<[IrisSessionDTO]> {
        let result = await client.sendRequest(GetChatSessionsRequest(courseId: courseId))
        switch result {
        case .success(let response):
            return .done(response: response.0)
        case .failure(let error):
            return .failure(error: UserFacingError(error: error))
        }
    }

    struct GetChatSessionRequest: APIRequest {
        typealias Response = IrisSession

        let courseId: Int
        let sessionId: Int

        var method: HTTPMethod { .get }

        var resourceName: String {
            "api/iris/chat/courses/\(courseId)/sessions/\(sessionId)"
        }
    }

    func getChatSession(courseId: Int, sessionId: Int) async -> DataState<IrisSession> {
        let result = await client.sendRequest(GetChatSessionRequest(courseId: courseId, sessionId: sessionId))
        switch result {
        case .success(let response):
            return .done(response: response.0)
        case .failure(let error):
            return .failure(error: UserFacingError(error: error))
        }
    }

    struct GetSessionAndMessageCountRequest: APIRequest {
        typealias Response = IrisSessionCountDTO

        var method: HTTPMethod { .get }

        var resourceName: String {
            "api/iris/chat/sessions/count"
        }
    }

    func getSessionAndMessageCount() async -> DataState<IrisSessionCountDTO> {
        let result = await client.sendRequest(GetSessionAndMessageCountRequest())
        switch result {
        case .success(let response):
            return .done(response: response.0)
        case .failure(let error):
            return .failure(error: UserFacingError(error: error))
        }
    }

    struct DeleteAllSessionsRequest: APIRequest {
        typealias Response = RawResponse

        var method: HTTPMethod { .delete }

        var resourceName: String {
            "api/iris/chat/sessions"
        }
    }

    func deleteAllSessions() async -> NetworkResponse {
        let result = await client.sendRequest(DeleteAllSessionsRequest())
        switch result {
        case .success:
            return .success
        case .failure(let error):
            return .failure(error: error)
        }
    }

    struct DeleteSessionRequest: APIRequest {
        typealias Response = RawResponse

        let sessionId: Int

        var method: HTTPMethod { .delete }

        var resourceName: String {
            "api/iris/chat/sessions/\(sessionId)"
        }
    }

    func deleteSession(sessionId: Int) async -> NetworkResponse {
        let result = await client.sendRequest(DeleteSessionRequest(sessionId: sessionId))
        switch result {
        case .success:
            return .success
        case .failure(let error):
            return .failure(error: error)
        }
    }

    // MARK: - Messages

    struct GetMessagesRequest: APIRequest {
        typealias Response = [IrisMessageResponseDTO]

        let sessionId: Int

        var method: HTTPMethod { .get }

        var resourceName: String {
            "api/iris/sessions/\(sessionId)/messages"
        }
    }

    func getMessages(sessionId: Int) async -> DataState<[IrisMessageResponseDTO]> {
        let result = await client.sendRequest(GetMessagesRequest(sessionId: sessionId))
        switch result {
        case .success(let response):
            return .done(response: response.0)
        case .failure(let error):
            return .failure(error: UserFacingError(error: error))
        }
    }

    struct SendMessageRequest: APIRequest {
        typealias Response = IrisMessageResponseDTO

        let sessionId: Int
        let messageRequest: IrisMessageRequestDTO

        var method: HTTPMethod { .post }

        var resourceName: String {
            "api/iris/sessions/\(sessionId)/messages"
        }

        func encode(to encoder: Encoder) throws {
            try messageRequest.encode(to: encoder)
        }
    }

    func sendMessage(sessionId: Int, request: IrisMessageRequestDTO) async -> DataState<IrisMessageResponseDTO> {
        let result = await client.sendRequest(SendMessageRequest(sessionId: sessionId, messageRequest: request))
        switch result {
        case .success(let response):
            return .done(response: response.0)
        case .failure(let error):
            return .failure(error: UserFacingError(error: error))
        }
    }

    struct ResendMessageRequest: APIRequest {
        typealias Response = IrisMessageResponseDTO

        let sessionId: Int
        let messageId: Int

        var method: HTTPMethod { .post }

        var resourceName: String {
            "api/iris/sessions/\(sessionId)/messages/\(messageId)/resend"
        }
    }

    func resendMessage(sessionId: Int, messageId: Int) async -> DataState<IrisMessageResponseDTO> {
        let result = await client.sendRequest(ResendMessageRequest(sessionId: sessionId, messageId: messageId))
        switch result {
        case .success(let response):
            return .done(response: response.0)
        case .failure(let error):
            return .failure(error: UserFacingError(error: error))
        }
    }

    struct RateMessageRequest: APIRequest {
        typealias Response = IrisMessageResponseDTO

        let sessionId: Int
        let messageId: Int
        let helpful: Bool

        var method: HTTPMethod { .put }

        var resourceName: String {
            "api/iris/sessions/\(sessionId)/messages/\(messageId)/helpful"
        }

        /// Server expects the raw boolean as the request body, not an object wrapper.
        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(helpful)
        }
    }

    func rateMessage(sessionId: Int, messageId: Int, helpful: Bool) async -> DataState<IrisMessageResponseDTO> {
        let result = await client.sendRequest(RateMessageRequest(sessionId: sessionId, messageId: messageId, helpful: helpful))
        switch result {
        case .success(let response):
            return .done(response: response.0)
        case .failure(let error):
            return .failure(error: UserFacingError(error: error))
        }
    }
}
