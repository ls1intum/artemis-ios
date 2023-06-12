//
//  DashboardHandler.swift
//  
//
//  Created by Sven Andabaka on 11.04.23.
//

import Foundation

struct DashboardHandler: Deeplink {

    static func build(from url: URL) -> DashboardHandler? {
        if url.pathComponents.isEmpty || (url.pathComponents.contains("courses") && url.pathComponents.count < 2) {
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
