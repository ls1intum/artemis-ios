//
//  IrisSessionListViewModel.swift
//  ArtemisKit
//
//  Created by Senan Aslan on 25.05.26.
//

import Common
import Foundation
import SwiftUI

@MainActor
@Observable
final class IrisSessionListViewModel {
    private let courseId: Int
    private let httpService: IrisChatHttpService

    var sessions: [IrisSessionDTO] = []

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

    init(courseId: Int, httpService: IrisChatHttpService = IrisChatHttpServiceFactory.shared) {
        self.courseId = courseId
        self.httpService = httpService
    }

    func loadSessions() async {
        isLoading = true
        let result = await httpService.getChatSessions(courseId: courseId)
        switch result {
        case .done(let response):
            sessions = response.sorted { $0.creationDate > $1.creationDate }
        case .failure(let error):
            self.error = error
        case .loading:
            break
        }
        isLoading = false
    }

    func createNewSession() async -> Int? {
        isLoading = true
        let result = await httpService.createSession(mode: .course, entityId: courseId)
        switch result {
        case .done(let response):
            isLoading = false
            return response.id
        case .failure(let error):
            isLoading = false
            self.error = error
            return nil
        case .loading:
            isLoading = false
            return nil
        }
    }

    func deleteSession(sessionId: Int) async {
        let result = await httpService.deleteSession(sessionId: sessionId)
        switch result {
        case .success:
            sessions.removeAll { $0.id == sessionId }
        case .failure(let error):
            self.error = UserFacingError(title: error.localizedDescription)
        case .loading, .notStarted:
            break
        }
    }
}

extension IrisSessionListViewModel {
    struct GroupedSessions: Identifiable {
        let title: String
        let sessions: [IrisSessionDTO]

        var id: String { title }
    }

    var groupedSessions: [GroupedSessions] {
        let now = Date()
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
