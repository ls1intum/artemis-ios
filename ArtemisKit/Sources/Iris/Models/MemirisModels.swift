//
//  MemirisModels.swift
//  ArtemisKit
//
//  Created by Senan Aslan on 09.05.26.
//

/// A single memory in Iris' "Memiris" memory system.
/// Wire JSON uses `slept_on` (snake_case) — the rest of the wire uses camelCase.
struct MemirisMemory: Codable, Hashable, Identifiable {
    let id: String
    let title: String
    let content: String
    /// IDs of learnings associated with this memory.
    let learnings: [String]
    /// IDs of memory connections.
    let connections: [String]
    let sleptOn: Bool
    let deleted: Bool

    private enum CodingKeys: String, CodingKey {
        case id, title, content, learnings, connections, deleted
        case sleptOn = "slept_on"
    }
}

struct MemirisLearningDTO: Codable, Hashable, Identifiable {
    let id: String
    let title: String
    let content: String
    let reference: String?
    /// Related memory IDs.
    let memories: [String]
}

struct MemirisMemoryConnectionDTO: Codable, Hashable, Identifiable {
    let id: String
    let connectionType: String
    /// Related memory IDs.
    let memories: [String]
    let description: String?
    let weight: Double?
}

struct MemirisMemoryWithRelationsDTO: Codable, Hashable, Identifiable {
    let id: String
    let title: String
    let content: String
    let sleptOn: Bool
    let deleted: Bool
    let learnings: [MemirisLearningDTO]
    let connections: [MemirisMemoryConnectionDTO]
}

struct MemirisMemoryDataDTO: Codable, Hashable {
    let memories: [MemirisMemory]
    let learnings: [MemirisLearningDTO]
    let connections: [MemirisMemoryConnectionDTO]
}
