//
//  SearchFilter.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 21.03.26.
//

import SwiftUI

enum SearchFilter: CaseIterable, Identifiable, Equatable {
    case iris
    case exercises
    case lectures

    var displayTitle: String {
        switch self {
        case .iris:
            "Ask Iris"
        case .exercises:
            "Exercises"
        case .lectures:
            "Lectures"
        }
    }

    var color: Color {
        switch self {
        case .iris:
            Color.blue
        case .exercises:
            Color.orange
        case .lectures:
            Color.orange
        }
    }

    var systemImage: String {
        switch self {
        case .iris:
            "eyes.inverse"
        case .exercises:
            "list.bullet.clipboard.fill"
        case .lectures:
            "character.book.closed.fill"
        }
    }

    var id: String {
        self.displayTitle
    }
}
