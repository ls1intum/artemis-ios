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

    var isMemberPickerSuppressed = false {
        didSet {
            updatePresentation()
        }
    }

    var isChannelPickerSuppressed = false {
        didSet {
            updatePresentation()
        }
    }

    var isExercisePickerPresented = false
    var isLecturePickerPresented = false
}

// MARK: - Action

extension SendMessageViewModel {
    func didTapAtButton() {
        if isMemberPickerPresented {
            isMemberPickerSuppressed = true
        } else {
            isMemberPickerSuppressed = false
            text += "@"
        }
    }

    func didTapNumberButton() {
        if isChannelPickerPresented {
            isChannelPickerSuppressed = true
        } else {
            isChannelPickerSuppressed = false
            text += "#"
        }
    }
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
    func updatePresentation() {
        switch (
            presentation,
            SendMessageMemberCandidate.search(text: text),
            SendMessageChannelCandidate.search(text: text)
        ) {
        case (_, .some, _) where !isMemberPickerSuppressed:
            presentation = .memberPicker
        case (_, _, .some) where !isChannelPickerSuppressed:
            presentation = .channelPicker
        case (.some, _, _):
            fallthrough
        default:
            presentation = nil
        }
    }
}
