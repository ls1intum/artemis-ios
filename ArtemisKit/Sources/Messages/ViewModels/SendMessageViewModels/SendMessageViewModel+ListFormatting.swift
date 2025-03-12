//
//  SendMessageViewModel+ListFormatting.swift.swift
//  ArtemisKit
//
//  Created by Eylul Naz Can on 28.02.2025.
//

import Foundation
import SwiftUI

extension SendMessageViewModel {

    func handleListFormatting(_ newValue: String) {
        let modifiedText = SendMessageListUtil.handleTextChange(newValue, text: text)
        if modifiedText != text {
            text = modifiedText
            moveCursorToEnd()
        }
    }

    // Inserts the list prefix using our utility and updates the text.
    func insertListPrefix(unordered: Bool) {
        text = SendMessageListUtil.insertListPrefix(text: text, unordered: unordered)
        moveCursorToEnd()
    }

    func moveCursorToEnd() {
        _selection = TextSelection(insertionPoint: text.endIndex)
    }

    func makeInsertion(insertionPoint: String.Index) {
        _selection = TextSelection(insertionPoint: insertionPoint)
    }
}
