//
//  MessageRequestFilter.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 16.11.24.
//

import Foundation
import SharedModels
import SwiftUI
import UserStore

class MessageRequestFilter: Codable {
    var filters: [FilterOption]

    init(filterToUnresolved: Bool = false,
         filterToOwn: Bool = false,
         filterToAnsweredOrReacted: Bool = false,
         pinnedOnly: Bool = false) {
        self.filters = [
            .init(name: .filterToUnresolved, enabled: filterToUnresolved),
            .init(name: .filterToOwn, enabled: filterToOwn),
            .init(name: .filterToAnsweredOrReacted, enabled: filterToAnsweredOrReacted),
            .init(name: .pinnedOnly, enabled: pinnedOnly)
        ]
    }

    var selectedFilter: String {
        get {
            self.filters.first { $0.enabled }?.name ?? "all"
        }
        set {
            if newValue == "all" {
                self.filters = self.filters.map {
                    FilterOption(name: $0.name, enabled: false)
                }
            } else {
                self.filters = self.filters.map {
                    FilterOption(name: $0.name, enabled: $0.name == newValue)
                }
            }
        }
    }

    func messageMatchesSelectedFilter(_ message: Message) -> Bool {
        guard let activeFilter = filters.first(where: { $0.enabled })?.name else {
            return true
        }

        switch activeFilter {
        case .filterToAnsweredOrReacted:
            let answered = message.answers?.contains(where: { $0.isCurrentUserAuthor }) ?? false
            let reacted = message.reactions?.contains(where: { $0.user?.id == UserSessionFactory.shared.user?.id }) ?? false
            return answered || reacted
        case .filterToOwn:
            let isOwn = message.isCurrentUserAuthor
            let didReply = message.answers?.contains { $0.isCurrentUserAuthor } ?? false
            return isOwn || didReply
        case .filterToUnresolved:
            return !(message.resolved ?? false)
        case .pinnedOnly:
            return message.displayPriority == .pinned
        default:
            return true
        }
    }

    var queryItems: [URLQueryItem] {
        let items: [URLQueryItem] = filters.compactMap { filter in
            if filter.enabled {
                return .init(name: filter.name, value: "true")
            } else {
                return nil
            }
        }
        return items
    }
}

struct FilterOption: Codable, Hashable {
    let name: String
    let enabled: Bool

    var displayName: String {
        switch name {
        case .filterToAnsweredOrReacted:
            return R.string.localizable.messageFilterReacted()
        case .filterToUnresolved:
            return R.string.localizable.messageFilterUnresolved()
        case .filterToOwn:
            return R.string.localizable.messageFilterOwn()
        case .pinnedOnly:
            return R.string.localizable.pinned()
        default:
            return ""
        }
    }
}

// MARK: String+Filter
fileprivate extension String {
    static let filterToAnsweredOrReacted = "filterToAnsweredOrReacted"
    static let filterToUnresolved = "filterToUnresolved"
    static let filterToOwn = "filterToOwn"
    static let pinnedOnly = "pinnedOnly"
}
