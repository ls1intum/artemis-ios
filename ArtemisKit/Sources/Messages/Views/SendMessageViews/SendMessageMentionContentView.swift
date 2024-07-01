//
//  SendMessageMentionContentView.swift
//
//
//  Created by Nityananda Zbil on 30.05.24.
//

import SwiftUI

struct SendMessageMentionContentView: View {

    @Bindable var viewModel: SendMessageViewModel
    let type: MessageMentionContentType

    var body: some View {
        NavigationStack {
            let delegate = SendMessageMentionContentDelegate { [weak viewModel] mention in
                viewModel?.text.append(mention)
                viewModel?.wantsToAddMessageMentionContentType = nil
            }
            Group {
                switch type {
                case .exercise:
                    SendMessageExercisePicker(delegate: delegate, course: viewModel.course)
                case .lecture:
                    SendMessageLecturePicker(course: viewModel.course, delegate: delegate)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(R.string.localizable.cancel()) {
                        viewModel.wantsToAddMessageMentionContentType = nil
                    }
                }
            }
        }
    }
}

enum MessageMentionContentType: Identifiable {
    var id: Self {
        self
    }

    case exercise
    case lecture
}
