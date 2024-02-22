//
//  SendMessageViewModel.swift
//
//
//  Created by Nityananda Zbil on 22.02.24.
//

import Foundation

@Observable
final class SendMessageViewModel {

    enum Presentation {
        case memberPicker
        case channelPicker
    }

    var text: String = "" {
        didSet {
            updatePresentation()
        }
    }

    private(set) var presentation: Presentation?

    var isMemberPickerSuppressed = false
    var isChannelPickerSuppressed = false

    var isExercisePickerPresented = false
    var isLecturePickerPresented = false
}

// MARK: - Presentation

extension SendMessageViewModel {
    var isMemberPickerPresented: Bool {
        presentation == .memberPicker
    }

    var isChannelPickerPresented: Bool {
        presentation == .channelPicker
    }
}

private extension SendMessageViewModel {
    /// .
    ///
    /// If a presentation is and a second wants to be,
    /// then find out the next…
    func updatePresentation() {
        switch (
            presentation,
            SendMessageMemberCandidate.search(text: text),
            SendMessageChannelCandidate.search(text: text)
        ) {
        case (.some, _, _):
            break
        case (_, .some, _) where !isMemberPickerSuppressed:
            presentation = .memberPicker
        case (_, _, .some) where !isChannelPickerSuppressed:
            presentation = .channelPicker
        default:
            break
        }
    }
}
