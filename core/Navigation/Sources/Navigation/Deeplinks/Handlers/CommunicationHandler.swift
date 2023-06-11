//
//  NewReplyOnCoursePostHandler.swift
//  
//
//  Created by Sven Andabaka on 12.03.23.
//

import Foundation

struct CommunicationHandler: Deeplink {

    let url: URL

    static func build(from url: URL) -> CommunicationHandler? {
        guard url.pathComponents.contains(where: { $0 == "courses" }),
              url.pathComponents.contains(where: { $0 == "discussion" }) else { return nil }

        return CommunicationHandler(url: url)
    }

    func handle(with navigationController: NavigationController) {
        DispatchQueue.main.async {
            navigationController.popToRoot()
            navigationController.showDeeplinkNotSupported(url: url)
        }
    }
}
