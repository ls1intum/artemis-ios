//
//  IrisMessageContent.swift
//  ArtemisKit
//
//  Created by Senan Aslan on 09.05.26.
//

import SharedModels

enum IrisMessageContentType: String, ConstantsEnum {
    case text
    case json
    case unknown
}

/// Plain-text message content used by user, assistant and artifact messages.
struct IrisTextMessageContent: Hashable {
    let id: Int64?
    let messageId: Int64?
    let textContent: String
}

/// Structured JSON content. Currently used for MCQs in assistant messages.
/// The wire format carries `attributes` as a JSON-encoded string
/// (see `IrisMessageContentResponseDTO.attributes`); the chat service decodes
/// that string into the typed `IrisJsonAttributes` payload below.
struct IrisJsonMessageContent: Hashable {
    let id: Int64?
    let messageId: Int64?
    let attributes: IrisJsonAttributes
}

/// Discriminated union over the JSON attribute payloads Iris currently sends.
/// Matches the type-guard logic in `iris-content-type.model.ts` (`isMcqContent`,
/// `isMcqSetContent`).
enum IrisJsonAttributes: Hashable {
    case mcq(McqData)
    case mcqSet(McqSetData)
    case unknown
}

/// Domain content union for in-app use. Wire decoding goes through
/// `IrisMessageContentResponseDTO`; conversion happens in the chat service.
enum IrisMessageContent: Hashable {
    case text(IrisTextMessageContent)
    case json(IrisJsonMessageContent)
}

// MARK: - MCQ payloads

struct McqOption: Codable, Hashable {
    let text: String
    let correct: Bool
}

struct McqQuestionData: Codable, Hashable {
    let question: String
    let options: [McqOption]
    let explanation: String
}

struct McqData: Codable, Hashable {
    let type: String
    let question: String
    let options: [McqOption]
    let explanation: String
    let response: McqResponseData?
}

struct McqSetData: Codable, Hashable {
    let type: String
    let questions: [McqQuestionData]
    let responses: [McqResponseData]?
}

struct McqResponseData: Codable, Hashable {
    let selectedIndex: Int
    let submitted: Bool
    let questionIndex: Int?
}
