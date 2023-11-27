//
//  CodeOfConductView.swift
//
//
//  Created by Nityananda Zbil on 15.10.23.
//

import ArtemisMarkdown
import DesignLibrary
import SharedModels
import SwiftUI

struct CodeOfConductView: View {

    @StateObject private var viewModel: CodeOfConductViewModel

    init(course: Course) {
        self._viewModel = StateObject(wrappedValue: CodeOfConductViewModel(course: course))
    }

    var body: some View {
        DataStateView(data: $viewModel.codeOfConduct) {
            await viewModel.getCodeOfConductInformation()
        } content: { _ in
            VStack(alignment: .leading) {
                ArtemisMarkdownView(string: codeOfConductSanitized() + "\n" + responsibleUserMarkdown())
                // Take all available horizontal space
                HStack {
                    Spacer()
                }
            }
        }
        .task {
            await viewModel.getCodeOfConductInformation()
        }
    }
}

private extension CodeOfConductView {
    /// `codeOfConductSanitized` filters HTML comments.
    func codeOfConductSanitized() -> String {
        (viewModel.codeOfConduct.value ?? "")
            .split(separator: "\n")
            .filter { line in
                let isComment = line.hasPrefix("<!--") && line.hasSuffix("-->")
                return !isComment
            }
            .joined(separator: "\n")
    }

    /// `responsibleUserMarkdown` creates a Markdown string from the responsible users array.
    func responsibleUserMarkdown() -> String {
        (viewModel.responsibleUsers.value ?? [])
            .map { user in
                "- \(user.name) ([\(user.email)](mailto:\(user.email)))"
            }
            .joined(separator: "\n")
    }
}
