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

    private init() { }

    func setup(navigationController: NavigationController) {
        self.navigationController = navigationController
    }

    public func handle(path: String) {
        guard let url = URL(string: path, relativeTo: UserSession.shared.institution?.baseURL) else { return }
        handle(url: url)
    }

    public func handle(url: URL) {
        guard let navigationController else {
            return
        }
        buildHandler(from: url)?.handle(with: navigationController)
    }

    private func buildHandler(from url: URL) -> Deeplink? {
        // warning: the order of the array matters
        let builderFuncs: [(URL) -> Deeplink?] = [
            ExerciseHandler.build,
            LectureHandler.build,
            MessageHandler.build,
            MessagesHandler.build,
            CourseHandler.build,
            DashboardHandler.build,
            UnknownLinkHandler.build
        ]

        return builderFuncs
            .map { $0(url) }
            .compactMap { $0 }
            .first
    }
}

extension URL {
    func trimBaseUrl() -> String? {
        let string = self.absoluteString

        guard let baseURL = UserSession.shared.institution?.baseURL,
              let endIndex = string.range(of: baseURL.absoluteString)?.upperBound else { return nil }

        return String(string.suffix(from: endIndex))
    }
}
