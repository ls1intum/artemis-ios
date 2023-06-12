//
//  File.swift
//  
//
//  Created by Sven Andabaka on 12.06.23.
//

import Foundation

struct UnknownLinkHandler: Deeplink {

    let url: URL

    static func build(from url: URL) -> UnknownLinkHandler? {
        return UnknownLinkHandler(url: url)
    }

    func handle(with navigationController: NavigationController) {
        Task(priority: .userInitiated) {
            await navigationController.showDeeplinkNotSupported(url: url)
        }
    }
}
