//
//  MessageRequestFilter.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 16.11.24.
//

import Foundation
import SwiftUI

class MessageRequestFilter: Codable {
    var filters: [FilterOption]

    init(filterToUnresolved: Bool = false,
         filterToOwn: Bool = false,
         filterToAnsweredOrReacted: Bool = false) {
        self.filters = [
            .init(name: "filterToUnresolved", enabled: filterToUnresolved),
            .init(name: "filterToOwn", enabled: filterToOwn),
            .init(name: "filterToAnsweredOrReacted", enabled: filterToAnsweredOrReacted)
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

    var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = filters.compactMap { filter in
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
        // TODO: Localize
        switch name {
        case "filterToAnsweredOrReacted":
            return "Reacted"
        case "filterToUnresolved":
            return "Unresolved"
        case "filterToOwn":
            return "Own"
        default:
            return ""
        }
    }
}
