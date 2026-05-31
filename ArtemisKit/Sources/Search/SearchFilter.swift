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
    case communication

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
        case .communication:
            R.string.localizable.communication()
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
        case .communication:
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
        case .communication:
            "bubble.right.fill"
        }
    }

    var apiFilterTypes: [SearchFilterType]? {
        switch self {
        case .iris: nil
        case .exercises: [.exercise]
        case .lectures: [.lecture, .lectureUnit]
        case .faq: [.faq]
        case .communication: [.post, .answerPost, .channel]
        }
    }

    var id: String {
        self.displayTitle
    }
}
