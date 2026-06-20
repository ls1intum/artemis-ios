//
//  IrisSessionListViewModel.swift
//  ArtemisKit
//
//  Created by Senan Aslan on 25.05.26.
//

import Common
import Foundation
import SwiftUI
import APIClient

@MainActor
@Observable
final class IrisSessionListViewModel {
    private let courseId: Int
    private let httpService: IrisChatHttpService

    var sessions: DataState<[IrisSessionDTO]> = .loading
    var error: UserFacingError?
    var isLoading = false
    var isCreatingSession = false
    var searchText: String = ""

    var showError: Binding<Bool> {
        Binding(get: {
            self.error != nil
        }, set: { newValue in
            if !newValue {
                self.error = nil
            }
        })
    }

    init(courseId: Int, httpService: IrisChatHttpService = IrisChatHttpServiceFactory.shared) {
        self.courseId = courseId
        self.httpService = httpService
    }

    func loadSessions() async {
        let chatSessions = await httpService.getChatSessions(courseId: courseId)
        switch chatSessions {
        case .loading:
            sessions = .loading
        case .failure(let error):
            sessions = .failure(error: error)
        case .done(let response):
            sessions = .done(response: response.sorted { $0.creationDate > $1.creationDate })
        }
    }

    func createNewSession() async -> IrisSessionDTO? {
        var session: IrisSessionDTO?

        isCreatingSession = true
        defer {
            isCreatingSession = false
        }

        let result = await httpService.createSession(courseId: courseId)
        switch result {
        case .failure(let error):
            self.error = error
        case .done(let response):
            let dto = IrisSessionDTO(
                id: response.id,
                title: response.title,
                creationDate: response.creationDate,
                mode: response.mode ?? .course,
                entityId: response.entityId,
                entityName: nil)
            session = dto
            sessions.value?.insert(dto, at: 0)
        case .loading:
            break
        }

        return session
    }

    func deleteSession(sessionId: Int) async -> Bool {
        isLoading = true
        defer {
            isLoading = false
        }
        let result = await httpService.deleteSession(sessionId: sessionId)
        switch result {
        case .success:
            removeSession(sessionId: sessionId)
            return true
        case .failure(let error):
            if let apiClientError = error as? APIClientError {
                self.error = UserFacingError(error: apiClientError)
            } else {
                self.error = UserFacingError(title: error.localizedDescription)
            }
            return false
        case .loading, .notStarted:
            isLoading = true
            return false
        }
    }

    func removeSession(sessionId: Int) {
        sessions.value?.removeAll(where: { $0.id == sessionId })
    }

    func updateSessionTitle(sessionId: Int, title: String) {
        guard let index = sessions.value?.firstIndex(where: { $0.id == sessionId }),
              let session = sessions.value?[index] else { return }
        sessions.value?[index] = session.withTitle(title)
    }

    /// Mirrors a live context switch from the open chat back into the list row,
    /// so its icon and entity name update without waiting for a full reload.
    func updateSessionContext(sessionId: Int, context: SessionContext) {
        guard let index = sessions.value?.firstIndex(where: { $0.id == sessionId }),
              let session = sessions.value?[index] else { return }
        sessions.value?[index] = session.withContext(context)
    }

    /// The current DTO for `sessionId` from the loaded list — the source of truth
    /// for a row's title/context, kept current by the `updateSession*` mutators.
    /// Used to seed the chat when it opens.
    func session(for sessionId: Int) -> IrisSessionDTO? {
        sessions.value?.first { $0.id == sessionId }
    }
}

extension IrisSessionListViewModel {
    struct GroupedSessions: Identifiable {
        let title: String
        let sessions: [IrisSessionDTO]

        var id: String { title }
    }

    private var filteredSessions: [IrisSessionDTO] {
        let allSessions = sessions.value ?? []
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespaces)
        guard !trimmedSearch.isEmpty else { return allSessions }
        return allSessions.filter { session in
            session.title?.localizedCaseInsensitiveContains(trimmedSearch) ?? false
        }
    }

    var groupedSessions: [GroupedSessions] {
        let now = Date()
        let sessions = filteredSessions
        let today = sessions.filter { Calendar.current.isDateInToday($0.creationDate) }
        let yesterday = sessions.filter { Calendar.current.isDateInYesterday($0.creationDate) }

        let sevenDayCutoff = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
        let last7Days = sessions.filter { session in
            session.creationDate > sevenDayCutoff
                && !Calendar.current.isDateInToday(session.creationDate)
                && !Calendar.current.isDateInYesterday(session.creationDate)
        }

        let thirtyDayCutoff = Calendar.current.date(byAdding: .day, value: -30, to: now) ?? now
        let last30Days = sessions.filter { session in
            session.creationDate > thirtyDayCutoff
                && session.creationDate <= sevenDayCutoff
        }

        let older = sessions.filter { $0.creationDate <= thirtyDayCutoff }

        let buckets: [(String, [IrisSessionDTO])] = [
            (R.string.localizable.sectionToday(), today),
            (R.string.localizable.sectionYesterday(), yesterday),
            (R.string.localizable.sectionLast7Days(), last7Days),
            (R.string.localizable.sectionLast30Days(), last30Days),
            (R.string.localizable.sectionOlder(), older)
        ]

        return buckets.compactMap { title, sessions in
            sessions.isEmpty ? nil : GroupedSessions(title: title, sessions: sessions)
        }
    }
}
