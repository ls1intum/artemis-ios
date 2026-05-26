//
//  IrisMessageContentDTO.swift
//  ArtemisKit
//
//  Created by Senan Aslan on 09.05.26.
//

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
