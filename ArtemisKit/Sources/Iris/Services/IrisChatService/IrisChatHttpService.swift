//
//  IrisChatHttpService.swift
//  ArtemisKit
//
//  Created by Senan Aslan on 17.05.26.
//

import Common

protocol IrisChatHttpService {
    func getCurrentOrCreateSession(mode: IrisChatMode, entityId: Int) async -> DataState<IrisSession>
    func createSession(mode: IrisChatMode, entityId: Int) async -> DataState<IrisSession>

    func getChatSessions(courseId: Int) async -> DataState<[IrisSessionDTO]>
    func getChatSession(courseId: Int, sessionId: Int) async -> DataState<IrisSession>

    func getSessionAndMessageCount() async -> DataState<IrisSessionCountDTO>

    func deleteAllSessions() async -> NetworkResponse
    func deleteSession(sessionId: Int) async -> NetworkResponse

    func getMessages(sessionId: Int) async -> DataState<[IrisMessageResponseDTO]>
    func sendMessage(sessionId: Int, request: IrisMessageRequestDTO) async -> DataState<IrisMessageResponseDTO>
    func resendMessage(sessionId: Int, messageId: Int) async -> DataState<IrisMessageResponseDTO>
    func rateMessage(sessionId: Int, messageId: Int, helpful: Bool) async -> DataState<IrisMessageResponseDTO>
}

enum IrisChatHttpServiceFactory: DependencyFactory {
    static let liveValue: IrisChatHttpService = IrisChatHttpServiceImpl()
}
