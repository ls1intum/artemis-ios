//
//  DeeplinkHandler.swift
//  Artemis
//
//  Created by Sven Andabaka on 12.03.23.
//  Copyright © 2023 orgName. All rights reserved.
//

import Foundation
import UserStore

protocol Deeplink {
    static func build(from url: URL) -> Self?
    func handle(with navigationController: NavigationController)
}

public class DeeplinkHandler {

    public static let shared = DeeplinkHandler()

    var navigationController: NavigationController?

    private let userSession: UserSession

    private init(
        userSession: UserSession = .shared
    ) {
        self.userSession = userSession
    }

    func setup(navigationController: NavigationController) {
        self.navigationController = navigationController
    }

    public func handle(path: String) {
        guard let url = URL(string: path, relativeTo: userSession.institution?.baseURL) else {
            return
        }
        handle(url: url)
    }

    /// - Returns: Whether a handler could handle the URL.
    @discardableResult
    public func handle(url: URL) -> Bool {
        guard url.host() == userSession.institution?.baseURL?.host(),
              let navigationController,
              let handler = buildHandler(from: url) else {
            return false
        }

        handler.handle(with: navigationController)

        return true
    }

    private func buildHandler(from url: URL) -> Deeplink? {
        // Attention: the order of the array matters
        let builders: [(URL) -> Deeplink?] = [
            ExerciseHandler.build,
            LectureHandler.build,
            MessageHandler.build,
            MessagesHandler.build,
            CourseHandler.build,
            DashboardHandler.build,
            UnknownLinkHandler.build
        ]

        return builders
            .compactMap { builder in
                builder(url)
            }
            .first
    }
}
