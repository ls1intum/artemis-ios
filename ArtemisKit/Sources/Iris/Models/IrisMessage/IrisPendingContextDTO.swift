//
//  IrisPendingContextDTO.swift
//  ArtemisKit
//
//  Created by Senan Aslan on 05.06.26.
//

import Foundation

/// Mirrors the server `IrisPendingContextDTO`.
struct IrisPendingContextDTO: Codable, Hashable {
    let mode: IrisChatMode
    let entityId: Int
}
