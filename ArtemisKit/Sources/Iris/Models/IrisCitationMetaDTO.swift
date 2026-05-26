//
//  IrisCitationMetaDTO.swift
//  ArtemisKit
//
//  Created by Senan Aslan on 09.05.26.
//

struct IrisCitationMetaDTO: Codable, Hashable {
    let entityId: Int
    let lectureTitle: String
    let lectureUnitTitle: String
    let lectureId: Int
    let courseId: Int
}
