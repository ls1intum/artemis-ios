//
//  ExerciseParticipationView.swift
//
//
//  Created by Nityananda Zbil on 10.12.23.
//

import SwiftUI

// swiftlint:disable line_length
private let problem = """
Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet.
"""
// swiftlint:enable line_length

public struct ExerciseParticipationView: View {

    enum Tab: String, CaseIterable, Identifiable {
        case submission
        case problemStatement

        var id: Self {
            self
        }
    }

    @State var selection = Tab.submission
    @State var text = "" {
        didSet {
            didSubmit = false
        }
    }
    @State var didSubmit = true

    public init() {}

    public var body: some View {
        VStack(alignment: .leading) {
            Picker("Tab", selection: $selection) {
                ForEach(Tab.allCases) { tab in
                    Text(String(describing: tab))
                }
            }
            .pickerStyle(.segmented)
            switch selection {
            case .submission:
                TextEditor(text: $text)
                    .overlay {
                        // Corner radius of segmented picker.
                        RoundedRectangle(cornerRadius: 9)
                            .stroke(Color.Artemis.artemisBlue)
                    }
            case .problemStatement:
                Text(problem)
                Spacer()
            }
        }
        .padding([.horizontal, .bottom])
        .onChange(of: text) {
            didSubmit = false
        }
        .navigationTitle("Exercise")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem {
                Button("Submit") {
                    didSubmit = true
                }
                .buttonStyle(.bordered)
                .disabled(didSubmit)
            }
        }
    }
}

extension ExerciseParticipationView.Tab: CustomStringConvertible {
    var description: String {
        switch self {
        case .submission:
            "Submission"
        case .problemStatement:
            "Problem Statement"
        }
    }
}

#Preview {
    NavigationStack {
        ExerciseParticipationView()
    }
}
