//
//  MultipleChoiceView.swift
//
//
//  Created by Nityananda Zbil on 23.12.23.
//

import SwiftUI

struct MultipleChoiceView: View {

    struct Exercise {

        struct Question {

            struct Choice {
                var title: String
                var hint: String?
                var explanation: String?
                var isOn: Bool

                var item: Hint?
            }

            var title: String

            var longQuestion: String?
            var hint: String?

            var choices: [Choice]

            var item: Hint?
        }

        var title: String
        var questions: [Question]
    }

    struct Hint: Identifiable {
        var message: String

        var id: String {
            message
        }
    }

    struct MultipleChoiceToggleStyle: ToggleStyle {
        func makeBody(configuration: Configuration) -> some View {
            HStack {
                configuration.label
                Button {
                    configuration.isOn.toggle()
                } label: {
                    if configuration.isOn {
                        Image(systemName: "checkmark.square.fill")
                    } else {
                        Image(systemName: "square")
                    }
                }
                .foregroundStyle(.foreground)
            }
            .padding()
            .background(.secondary.opacity(0.2), in: .rect(cornerRadius: 5))
        }
    }

    @Environment(\.isEnabled) var isEnabled

    @State var exercise = Exercise(
        title: "A Quiz Exercise",
        questions: [
            .init(
                title: "Multiple-choice question",
                longQuestion: "A very very very very very very very very very very very very very very very very very long question?",
                hint: "Something",
                choices: [
                    .init(
                        title: "Enter a correct answer option here",
                        hint: "This is correct",
                        explanation: "Add an explanation here (only visible in feedback after quiz has ended)",
                        isOn: false),
                    .init(title: "Maybe this is correct, too", isOn: false),
                    .init(title: "Enter a wrong answer option here", isOn: false)
                ]),
            .init(
                title: "What does every program say first?",
                hint: "Nothing",
                choices: [
                    .init(title: "Hello, world!", isOn: false)
                ])
        ])

    var body: some View {
        ScrollView {
            VStack {
                ForEach($exercise.questions, id: \.title, content: self.question)
            }
            .padding(.horizontal)
        }
        .navigationTitle(exercise.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem {
                Button("Submit") {
                    //
                }
            }
        }
    }
}

private extension MultipleChoiceView {
    func question(_ question: Binding<Exercise.Question>) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text(question.wrappedValue.title)
                    .font(.title2)
                Spacer()
                question.wrappedValue.hint.map { hint in
                    Button {
                        question.wrappedValue.item = Hint(message: hint)
                    } label: {
                        Image(systemName: "questionmark.circle.fill")
                    }
                    .popover(item: question.item) { item in
                        Text(item.message)
                            .padding(.horizontal)
                            .presentationCompactAdaptation(.popover)
                    }
                }
                Text("1 P")
                    .font(.body.bold())
            }
            question.wrappedValue.longQuestion.map(Text.init)
            ForEach(question.choices, id: \.title, content: self.choice)
            Text("Please check all correct answer options")
                .font(.footnote)
        }
        .padding()
        .background(.secondary.opacity(0.1), in: .rect(cornerRadius: 5))
    }

    func choice(_ choice: Binding<Exercise.Question.Choice>) -> some View {
        VStack {
            Toggle(isOn: choice.isOn) {
                HStack {
                    Text(choice.wrappedValue.title)
                    Spacer()
                    if isEnabled {
                        choice.wrappedValue.hint.map { hint in
                            Button {
                                choice.wrappedValue.item = Hint(message: hint)
                            } label: {
                                Image(systemName: "questionmark.circle.fill")
                            }
                            .popover(item: choice.item) { item in
                                Text(item.message)
                                    .padding(.horizontal)
                                    .presentationCompactAdaptation(.popover)
                            }
                        }
                    }
                }
            }
            .toggleStyle(MultipleChoiceToggleStyle())
            if !isEnabled {
                if let hint = choice.wrappedValue.hint {
                    HStack {
                        Image(systemName: "questionmark.circle.fill")
                        Text(hint)
                        Spacer()
                    }
                }
                if let explanation = choice.wrappedValue.explanation {
                    HStack(alignment: .top) {
                        Image(systemName: "exclamationmark.circle.fill")
                        Text(explanation)
                        Spacer()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        MultipleChoiceView()
            .disabled(false)
    }
}

#Preview {
    NavigationStack {
        MultipleChoiceView()
            .disabled(true)
    }
    .preferredColorScheme(.dark)
}
