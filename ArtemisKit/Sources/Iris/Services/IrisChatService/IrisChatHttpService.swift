//
//  IrisChatHttpService.swift
//  ArtemisKit
//
//  Created by Senan Aslan on 17.05.26.
//

import Common

protocol IrisChatHttpService {
    func getCurrentOrCreateSession(mode: ChatServiceMode, entityId: Int64) async -> DataState<IrisSession>
    func createSession(mode: ChatServiceMode, entityId: Int64) async -> DataState<IrisSession>

    func getChatSessions(courseId: Int) async -> DataState<[IrisSessionDTO]>
    func getChatSession(courseId: Int, sessionId: Int64) async -> DataState<IrisSession>

    func getSessionAndMessageCount() async -> DataState<IrisSessionCountDTO>

    func deleteAllSessions() async -> NetworkResponse
    func deleteSession(sessionId: Int64) async -> NetworkResponse

    func getMessages(sessionId: Int64) async -> DataState<[IrisMessageResponseDTO]>
    func sendMessage(sessionId: Int64, request: IrisMessageRequestDTO) async -> DataState<IrisMessageResponseDTO>
    func resendMessage(sessionId: Int64, messageId: Int64) async -> DataState<IrisMessageResponseDTO>
    func rateMessage(sessionId: Int64, messageId: Int64, helpful: Bool) async -> DataState<IrisMessageResponseDTO>
}

enum IrisChatHttpServiceFactory: DependencyFactory {
    static let liveValue: IrisChatHttpService = IrisChatHttpServiceImpl()
}
