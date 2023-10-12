//
//  File.swift
//  
//
//  Created by Nityananda Zbil on 10.10.23.
//

import Dependencies
import SharedModels
import SwiftUI
@testable import Messages

#Preview {
    NavigationStack {
        MessagesTabView(viewModel: withDependencies({ values in
            values.messagesService = MessagesServiceStub()
        }, operation: {
            MessagesTabViewModel(course: Course(
                id: 1,
                courseInformationSharingConfiguration: .messagingOnly))
        }), searchText: .constant(""))
        .navigationTitle("Advanced Aerospace Engineering 🚀")
        .navigationBarTitleDisplayMode(.inline)
        .modifier(AppStorePreview(title: "Communicate with students and instructors"))
    }
}
