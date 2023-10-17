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
                Markdown(codeOfConductSanitized() + "\n" + responsibleUserMarkdown())
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
}

private extension CodeOfConductView {
    /// `codeOfConductSanitized` filters HTML comments.
    func codeOfConductSanitized() -> String {
        codeOfConduct
            .split(separator: "\n")
            .filter { line in
                let isComment = line.hasPrefix("<!--") && line.hasSuffix("-->")
                return !isComment
            }
            .joined(separator: "\n")
    }

    /// `responsibleUserMarkdown` creates a Markdown string from the responsible users array.
    func responsibleUserMarkdown() -> String {
        responsibleUsers
            .map { user in
                "- \(user.name) ([\(user.email)](mailto:\(user.email)))"
            }
            .joined(separator: "\n")
    }
}
