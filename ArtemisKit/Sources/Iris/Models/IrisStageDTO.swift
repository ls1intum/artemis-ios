//
//  IrisStageDTO.swift
//  ArtemisKit
//
//  Created by Senan Aslan on 09.05.26.
//

import SharedModels

struct IrisStageDTO: Codable, Hashable {
    let name: String
    let weight: Int
    let state: IrisStageStateDTO
    let message: String
    /// Internal stages are not shown in the UI and are hidden from the user.
    let `internal`: Bool
    let chatMessage: String?
}

enum IrisStageStateDTO: String, ConstantsEnum {
    case notStarted = "NOT_STARTED"
    case inProgress = "IN_PROGRESS"
    case done = "DONE"
    case skipped = "SKIPPED"
    case error = "ERROR"
    case unknown
}
