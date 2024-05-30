//
//  MessageCellModel+MentionScheme.swift
//
//
//  Created by Nityananda Zbil on 25.03.24.
//

import Foundation

enum MentionScheme {
    case attachment
    case channel(Int64)
    case exercise(Int)
    case lecture(Int)
    case lectureUnit
    case member(String)
    case message
    case slide

    init?(_ url: URL) {
        guard url.scheme == "mention" else {
            return nil
        }
        switch url.host() {
        case "attachment":
            // attachment
            // mention://attachment/lecture/3/LectureAttachment_2024-05-24T21-05-08-351_d37182b7.png
            self = .attachment
        case "channel":
            if let id = Int64(url.lastPathComponent) {
                self = .channel(id)
                return
            }
        case "exercise":
            if let id = Int(url.lastPathComponent) {
                self = .exercise(id)
                return
            }
        case "lecture":
            if let id = Int(url.lastPathComponent) {
                self = .lecture(id)
                return
            }
        case "lecture-unit":
            // attachment unit
            // mention://lecture-unit/attachment-unit/7/AttachmentUnit_2024-05-24T21-12-25-915_Inheritance__part_1_.pdf
            self = .lectureUnit
        case "member":
            self = .member(url.lastPathComponent)
            return
        case "message":
            // message
            // mention://message/1
            self = .message
        case "slide":
            // slide
            // mention://slide/attachment-unit/10/slide/1
            self = .slide
        default:
            return nil
        }
        return nil
    }
}
