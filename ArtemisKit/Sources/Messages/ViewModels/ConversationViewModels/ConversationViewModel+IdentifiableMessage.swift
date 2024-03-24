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

extension Set where Element == IdentifiableMessage {
    func firstByCreationDate() -> Element.RawValue? {
        let sorted = sorted {
            if let lhs = $0.rawValue.creationDate, let rhs = $1.rawValue.creationDate {
                lhs.compare(rhs) == .orderedAscending
            } else {
                false
            }
        }
        return sorted.first?.rawValue
    }
}
