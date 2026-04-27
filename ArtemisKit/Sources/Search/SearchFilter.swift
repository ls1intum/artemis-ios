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
    case faq
    case channel

    var displayTitle: String {
        switch self {
        case .iris:
            R.string.localizable.askIris()
        case .exercises:
            R.string.localizable.exercises()
        case .lectures:
            R.string.localizable.lectures()
        case .faq:
            R.string.localizable.faq()
        case .channel:
            R.string.localizable.channel()
        }
    }

    var color: Color {
        switch self {
        case .iris:
            Color.blue
        case .exercises:
            Color.indigo
        case .lectures:
            Color.teal
        case .faq:
            Color.pink
        case .channel:
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
        case .faq:
            "questionmark.circle.fill"
        case .channel:
            "bubble.right.fill"
        }
    }

    var apiFilterType: SearchFilterType? {
        switch self {
        case .iris: nil
        case .exercises: .exercise
        case .lectures: .lecture
        case .faq: .faq
        case .channel: .channel
        }
    }

    var id: String {
        self.displayTitle
    }
}
