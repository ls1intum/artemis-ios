//
//  DashboardHandler.swift
//  
//
//  Created by Sven Andabaka on 11.04.23.
//

import Foundation

struct DashboardHandler: Deeplink {

    static func build(from url: URL) -> DashboardHandler? {
        if url.pathComponents.isEmpty || url.pathComponents.firstIndex(where: { $0 == "courses" }) != nil {
            return DashboardHandler()
        }
        return nil
    }

    func handle(with navigationController: NavigationController) {
        Task(priority: .userInitiated) {
            await navigationController.popToRoot()
        }
    }
}
