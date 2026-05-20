//
//  IrisWebsocketTopic.swift
//  ArtemisKit
//
//  Created by Senan Aslan on 19.05.26.
//

enum IrisWebsocketTopic {
    static func makeIrisChat(sessionId: Int64) -> String {
        "/user/topic/iris/\(sessionId)"
    }
}
