//
//  IrisMessageRequestDTO.swift
//  ArtemisKit
//
//  Created by Senan Aslan on 09.05.26.
//

/// Body for `POST /sessions/{sessionId}/messages`. Mirrors the server
/// `IrisMessageRequestDTO`. `uncommittedFiles` (path → content) is only
/// populated for programming-exercise chats.
struct IrisMessageRequestDTO: Codable, Hashable {
    let content: [IrisMessageContentDTO]
    let messageDifferentiator: Int?
    let uncommittedFiles: [String: String]

    init(content: [IrisMessageContentDTO],
         messageDifferentiator: Int? = nil,
         uncommittedFiles: [String: String] = [:]) {
        self.content = content
        self.messageDifferentiator = messageDifferentiator
        self.uncommittedFiles = uncommittedFiles
    }
}
