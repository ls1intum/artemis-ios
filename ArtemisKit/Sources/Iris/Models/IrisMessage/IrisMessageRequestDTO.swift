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
    let pendingContext: IrisPendingContextDTO?

    init(content: [IrisMessageContentDTO],
         messageDifferentiator: Int? = nil,
         uncommittedFiles: [String: String] = [:],
         pendingContext: IrisPendingContextDTO? = nil) {
        self.content = content
        self.messageDifferentiator = messageDifferentiator
        self.uncommittedFiles = uncommittedFiles
        self.pendingContext = pendingContext
    }
}

/// Wire format for a single content block when **sending** a message to Iris.
/// Matches the server `IrisMessageContentDTO` record. `jsonContent` is the
/// JSON-encoded string of the payload (e.g. an MCQ response), not a parsed object.
struct IrisMessageContentDTO: Codable, Hashable {
    let type: IrisMessageContentType?
    let textContent: String?
    let jsonContent: String?

    static func text(_ content: String) -> IrisMessageContentDTO {
        IrisMessageContentDTO(type: .text, textContent: content, jsonContent: nil)
    }

    static func json(_ content: String) -> IrisMessageContentDTO {
        IrisMessageContentDTO(type: .json, textContent: nil, jsonContent: content)
    }
}
