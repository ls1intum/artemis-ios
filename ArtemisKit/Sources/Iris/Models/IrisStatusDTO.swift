//
//  IrisStatusDTO.swift
//  ArtemisKit
//
//  Created by Senan Aslan on 09.05.26.
//

struct IrisStatusDTO: Codable, Hashable {
    let active: Bool
    let rateLimitInfo: IrisRateLimitInformation
}
