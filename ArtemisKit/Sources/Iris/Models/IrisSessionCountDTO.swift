//
//  IrisSessionCountDTO.swift
//  ArtemisKit
//
//  Created by Senan Aslan on 17.05.26.
//

import Foundation

/// Pair of session/message counters returned by `GET /chat/sessions/count`.
struct IrisSessionCountDTO: Codable, Hashable {
    let sessions: Int
    let messages: Int
}
