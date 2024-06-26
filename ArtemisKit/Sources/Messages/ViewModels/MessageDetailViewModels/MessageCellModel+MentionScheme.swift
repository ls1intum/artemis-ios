//
//  MessageCellModel+MentionScheme.swift
//
//
//  Created by Nityananda Zbil on 25.03.24.
//

import Foundation

enum MentionScheme {
    case attachment(filename: String, lectureId: Int)
    case channel(id: Int64)
    case exercise(id: Int)
    case lecture(id: Int)
    case lectureUnit(filename: String, attachmentUnit: Int)
    case member(login: String)
    case message(id: Int64)
    case slide(number: Int, attachmentUnit: Int)

    init?(_ url: URL) {
        guard url.scheme == "mention" else {
            return nil
        }
        switch url.host() {
        case "attachment":
            // E.g., mention://attachment/lecture/3/LectureAttachment_2024-05-24T21-05-08-351_d37182b7.png
            if url.pathComponents.count >= 3, let lectureId = Int(url.pathComponents[2]) {
                self = .attachment(filename: url.lastPathComponent, lectureId: lectureId)
                return
            }
        case "channel":
            if let id = Int64(url.lastPathComponent) {
                self = .channel(id: id)
                return
            }
        case "exercise":
            if let id = Int(url.lastPathComponent) {
                self = .exercise(id: id)
                return
            }
        case "lecture":
            if let id = Int(url.lastPathComponent) {
                self = .lecture(id: id)
                return
            }
        case "lecture-unit":
            // E.g., mention://lecture-unit/attachment-unit/7/AttachmentUnit_2024-05-24T21-12-25-915_Inheritance__part_1_.pdf
            if url.pathComponents.count >= 4, let attachmentUnit = Int(url.pathComponents[2]) {
                self = .lectureUnit(filename: url.lastPathComponent, attachmentUnit: attachmentUnit)
                return
            }
        case "member":
            self = .member(login: url.lastPathComponent)
            return
        case "message":
            // E.g., mention://message/1
            if let id = Int64(url.lastPathComponent) {
                self = .message(id: id)
                return
            }
        case "slide":
            // E.g., mention://slide/attachment-unit/10/slide/1
            if url.pathComponents.count >= 4, let attachmentUnit = Int(url.pathComponents[2]), let id = Int(url.lastPathComponent) {
                self = .slide(number: id, attachmentUnit: attachmentUnit)
                return
            }
        default:
            return nil
        }
        return nil
    }
}
