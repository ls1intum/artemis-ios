//
//  MessageDetailViewModel.swift
//
//
//  Created by Nityananda Zbil on 13.03.24.
//

import Foundation

@MainActor
@Observable
final class MessageDetailViewModel {
    var offlineAnswers: [OfflineMessageOrAnswer] = []

    func sendAnswerMessage(text: String) async {
        //
    }
}

private extension MessageDetailViewModel {
    func fetchOfflineAnswers() {
        //
    }
}

// offlineAnswers.remove
