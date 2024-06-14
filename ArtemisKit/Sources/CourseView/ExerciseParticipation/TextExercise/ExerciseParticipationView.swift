//
//  EditTextExerciseView.swift
//
//
//  Created by Nityananda Zbil on 10.12.23.
//

import SwiftUI

enum EditTextExerciseViewTab: String, CaseIterable, Identifiable {
    case submission
    case problemStatement

    var id: Self {
        self
    }
}

@Observable
final class EditTextExerciseViewModel {
    private let exerciseSubmissionService = TextExerciseSubmissionService()

    var tab: EditTextExerciseViewTab = .submission
    var text: String = ""
    var isSubmitted = false
}

public struct EditTextExerciseView: View {

    @State var viewModel: EditTextExerciseViewModel = .init()

    public init() {}

    public var body: some View {
        VStack(alignment: .leading) {
            Picker("Tab", selection: $viewModel.tab) {
                ForEach(EditTextExerciseViewTab.allCases) { tab in
                    Text(String(describing: tab))
                }
            }
            .pickerStyle(.segmented)
            switch viewModel.tab {
            case .submission:
                TextEditor(text: $viewModel.text)
                    .overlay {
                        // Corner radius of segmented picker.
                        RoundedRectangle(cornerRadius: 9)
                            .stroke(Color.Artemis.artemisBlue)
                    }
            case .problemStatement:
                Text("problem")
                Spacer()
            }
        }
        .padding([.horizontal, .bottom])
        .onChange(of: viewModel.text) {
            viewModel.isSubmitted = false
        }
        .navigationTitle("Exercise")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem {
                Button("Submit") {
                    viewModel.isSubmitted = true
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isSubmitted)
            }
        }
    }
}

// MARK: EditTextExerciseViewTab+CustomStringConvertible

extension EditTextExerciseViewTab: CustomStringConvertible {
    var description: String {
        switch self {
        case .submission:
            "Submission"
        case .problemStatement:
            "Problem Statement"
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        EditTextExerciseView()
    }
}
