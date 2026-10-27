import ReviewContent
import SharedModels
import SwiftUI

/// A native, Dynamic Type-friendly alternative to the spatial drop targets.
struct TrainingDropAnswers: View {
    @Environment(QuizViewModel.self) private var viewModel
    let question: DTO.DragAndDropQuizQuestionWithSolution
    @Binding var mappings: [DTO.DragAndDropMappingFromLiveClient]
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(Array((question.dropLocations ?? []).enumerated()), id: \.offset) { index, location in
                Menu {
                    Button("—") { select(nil, for: location.id) }
                    ForEach(question.dragItems ?? [], id: \.id) { item in
                        Button { select(item.id, for: location.id) } label: {
                            DragItemView(questionId: question.id, item: item)
                        }
                    }
                } label: {
                    HStack(alignment: .top) {
                        Text("\(TrainingCopy.text("input")) \(index + 1)").font(.headline)
                        Spacer(minLength: 12)
                        if let selected = mappings.first(where: { $0.dropLocation?.id == location.id })?.dragItem?.id,
                           let item = question.dragItems?.first(where: { $0.id == selected }) {
                            DragItemView(questionId: question.id, item: item)
                        } else { Image(systemName: "plus.circle") }
                    }.frame(minHeight: 44)
                }
                .accessibilityLabel("\(TrainingCopy.text("input")) \(index + 1)")
                .accessibilityIdentifier("training.drop.\(location.id ?? Int64(index))")
                .accessibilityValue(selectedText(for: location.id))
                .disabled(viewModel.locksAnswerEditing)
                Divider()
            }
        }
    }
    private func selectedText(for locationID: Int64?) -> String {
        let selected = mappings.first { $0.dropLocation?.id == locationID }?.dragItem?.id
        return question.dragItems?.first { $0.id == selected }?.text ?? ""
    }
    private func select(_ itemID: Int64?, for locationID: Int64?) {
        mappings = mappings.map { original in
            var mapping = original
            if mapping.dropLocation?.id == locationID { mapping.dragItem = itemID.map { .init(id: $0) } } else if mapping.dragItem?.id == itemID { mapping.dragItem = nil }
            return mapping
        }
    }
}
