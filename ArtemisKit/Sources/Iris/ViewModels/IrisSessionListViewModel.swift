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
    var searchText: String = ""

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

    func createNewSession() async {
        isLoading = true
        defer {
            isLoading = false
        }
        let result = await httpService.createSession(mode: .course, entityId: courseId)
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
            sessions.value?.append(dto)
        case .loading:
            isLoading = true
        }
    }

    func deleteSession(sessionId: Int) async {
        isLoading = true
        defer {
            isLoading = false
        }
        let result = await httpService.deleteSession(sessionId: sessionId)
        switch result {
        case .success:
            sessions.value?.removeAll(where: { $0.id == sessionId })
        case .failure(let error):
            if let apiClientError = error as? APIClientError {
                self.error = UserFacingError(error: apiClientError)
            } else {
                self.error = UserFacingError(title: error.localizedDescription)
            }
        case .loading, .notStarted:
            isLoading = true
        }
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
            ("Today", today),
            ("Yesterday", yesterday),
            ("Last 7 Days", last7Days),
            ("Last 30 Days", last30Days),
            ("Older", older)
        ]

        return buckets.compactMap { title, sessions in
            sessions.isEmpty ? nil : GroupedSessions(title: title, sessions: sessions)
        }
    }
}
