//
//  MessageCellModel+MentionScheme.swift
//
//
//  Created by Nityananda Zbil on 25.03.24.
//

import Foundation

enum MentionScheme {
    case channel(Int64)
    case exercise(Int)
    case lecture(Int)
    case member(String)

    init?(_ url: URL) {
        guard url.scheme == "mention" else {
            return nil
        }
        switch url.host() {
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
        case "member":
            self = .member(url.lastPathComponent)
            return
        default:
            return nil
        }
        return nil
    }
}
