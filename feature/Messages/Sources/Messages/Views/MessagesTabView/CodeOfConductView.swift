//
//  File.swift
//  
//
//  Created by Nityananda Zbil on 15.10.23.
//

import DesignLibrary
import MarkdownUI
import SwiftUI

struct CodeOfConductView: View {
    let codeOfConduct: String
    let responsibleUsers: [ResponsibleUserDTO]
    let acceptAction: (() async -> Void)?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Markdown(codeOfConduct + "\n" + responsibleUserMarkdown())
                if let acceptAction {
                    HStack {
                        Spacer()
                        Button {
                            Task {
                                await acceptAction()
                            }
                        } label: {
                            Text(R.string.localizable.acceptCodeOfConductButtonLabel())
                        }
                        .buttonStyle(ArtemisButton())
                        Spacer()
                    }
                }
            }
        }
        .padding()
    }

    private func responsibleUserMarkdown() -> String {
        responsibleUsers
            .map { user in
                "- \(user.name) ([\(user.email)](mailto:\(user.email)))"
            }
            .joined(separator: "\n")
    }
}
