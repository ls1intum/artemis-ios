//
//  IrisMessage.swift
//  ArtemisKit
//
//  Created by Senan Aslan on 09.05.26.
//

import SharedModels

/// Distinguishes the author of an Iris message.
enum IrisSender: String, ConstantsEnum {
    case llm = "LLM"
    case user = "USER"
    case artifact = "ARTIFACT"
    case unknown
}
