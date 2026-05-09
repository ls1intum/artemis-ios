//
//  IrisRateLimitInformation.swift
//  ArtemisKit
//
//  Created by Senan Aslan on 09.05.26.
//

struct IrisRateLimitInformation: Codable, Hashable {
    let currentMessageCount: Int
    let rateLimit: Int
    let rateLimitTimeframeHours: Int
}
