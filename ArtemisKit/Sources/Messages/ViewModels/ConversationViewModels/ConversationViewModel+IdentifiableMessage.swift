//
//  ConversationViewModel+IdentifiableMessage.swift
//
//
//  Created by Nityananda Zbil on 24.03.24.
//

import SharedModels

struct IdentifiableMessage: RawRepresentable {
    let rawValue: Message
}

extension IdentifiableMessage {
    static func of(id: ID) -> Self {
        .message(.init(id: id))
    }

    static func message(_ message: RawValue) -> Self {
        .init(rawValue: message)
    }
}

extension IdentifiableMessage: Equatable, Hashable, Identifiable {
    static func == (lhs: IdentifiableMessage, rhs: IdentifiableMessage) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    var id: Int64 {
        rawValue.id
    }
}

extension Collection where Element == IdentifiableMessage {
    func messages() -> [Element.RawValue] {
        map(\.rawValue)
    }

    func sortedByCreationDate() -> [Element.RawValue] {
        messages().sorted {
            if let lhs = $0.creationDate, let rhs = $1.creationDate {
                lhs.compare(rhs) == .orderedAscending
            } else {
                false
            }
        }
    }

    func firstByCreationDate() -> Element.RawValue? {
        sortedByCreationDate().first
    }
}
