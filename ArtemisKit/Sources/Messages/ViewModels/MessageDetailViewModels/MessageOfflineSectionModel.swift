//
//  MessageOfflineSectionModel.swift
//
//
//  Created by Nityananda Zbil on 14.03.24.
//

import Foundation

@MainActor
struct MessageOfflineSectionModelDelegate {
    let didSendOfflineAnswer: (MessageOfflineAnswerModel) async -> Void
}

@MainActor
@Observable
final class MessageOfflineSectionModel {
    let delegate: MessageOfflineSectionModelDelegate

    init(delegate: MessageOfflineSectionModelDelegate) {
        self.delegate = delegate
    }
}
