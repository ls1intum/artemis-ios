//
//  File.swift
//  
//
//  Created by Nityananda Zbil on 24.09.23.
//

import Common
import Dependencies
import Navigation
import SharedModels
import SharedServices
import SwiftUI

struct ConversationView_Previews: PreviewProvider {

    static var previews: some View {
        NavigationStack {
            ConversationView(viewModel: withDependencies({ values in
                values.messagesService = MessagesServiceStub()
            }, operation: {
                .init(
                    course: .init(
                        id: 1,
                        courseInformationSharingConfiguration: .communicationAndMessaging),
                    conversation: .oneToOneChat(conversation: .init(
                        type: .oneToOneChat,
                        id: 1)))
            }))
            .navigationTitle("Basic Operators")
            .navigationBarTitleDisplayMode(.inline)
            .environmentObject(NavigationController())
        }
    }
}
