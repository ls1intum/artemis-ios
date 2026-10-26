//
//  DNDQuestionView.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 07.06.26.
//

import DesignLibrary
import Extensions
import ReviewContent
import SharedModels
import SwiftUI

extension DTO.DragAndDropQuizQuestionWithSolution: WithImage {}

struct DNDQuestionView: View {
    @Environment(QuizViewModel.self) private var viewModel
    let question: DTO.QuizQuestionTraining
    let questionWithAnswer: DTO.DragAndDropQuizQuestionWithSolution

    @State private var mappings: [DTO.DragAndDropMappingFromLiveClient]

    var backgroundImage: URL? {
        questionWithAnswer.image(for: \.backgroundFilePath)
    }

    init(question: DTO.QuizQuestionTraining,
         questionWithAnswer: DTO.DragAndDropQuizQuestionWithSolution,
         previousAnswer: DTO.SubmittedAnswerFromLiveClient? = nil) {
        self.question = question
        self.questionWithAnswer = questionWithAnswer
        if let previousAnswer, case let .dragAndDrop(answer) = previousAnswer, var maps = answer.mappings {
            let mappedLocations = maps.compactMap(\.dropLocation).map(\.id)
            // Ensure all drop locations have a mapping to update!
            for location in questionWithAnswer.dropLocations ?? [] where !mappedLocations.contains(location.id) {
                maps.append(.init(dragItem: nil, dropLocation: .init(id: location.id)))
            }
            _mappings = State(initialValue: maps)
        } else {
            _mappings = State(initialValue: (questionWithAnswer.dropLocations ?? []).map {
                .init(dragItem: nil, dropLocation: .init(id: $0.id))
            })
        }
    }

    var body: some View {
        if let text = questionWithAnswer.text {
            if viewModel.usesSafeContent { SafeReviewContent(text).padding(.horizontal) } else { Text(LocalizedStringKey(text)).padding(.horizontal) }
        }

        Group {
            if viewModel.usesSafeContent { ReviewImage(path: questionWithAnswer.backgroundFilePath, filePath: true) } else {
                ArtemisAsyncImage(imageURL: backgroundImage) { Text("Failed to load image :/") }
            }
        }
        .scaledToFit()
        .modifier(TrainingQuestionImageWidth(training: viewModel is QuizTrainingViewModel))
        .overlay {
            DNDDropLocations(mappings: $mappings, question: questionWithAnswer)
        }

        if viewModel is QuizTrainingViewModel, !viewModel.hasSubmitted {
            TrainingDropAnswers(question: questionWithAnswer, mappings: $mappings)
                .padding(.horizontal)
        }

        if !viewModel.hasSubmitted {
            Text(viewModel is QuizTrainingViewModel ? TrainingCopy.text("dnd.info") : R.string.localizable.dndInfo())
                .font(.caption)
                .padding(.horizontal)
        }

        SubmitAnswerButton(questionId: question.id, isRated: question.isRated, answer: answer)
    }

    var answer: DTO.SubmittedAnswerFromLiveClient {
        .dragAndDrop(.init(quizQuestion: .init(id: question.id), mappings: mappings, _type: .dragAndDrop))
    }
}

struct DNDDropLocations: View {
    @Binding var mappings: [DTO.DragAndDropMappingFromLiveClient]

    let question: DTO.DragAndDropQuizQuestionWithSolution

    var body: some View {
        if let dropLocations = question.dropLocations,
           let dragItems = question.dragItems {
            GeometryReader { geo in
                ForEach(dropLocations, id: \.id) { location in
                    DropLocation(questionId: question.id,
                                 dragItems: dragItems,
                                 location: location,
                                 scaleX: geo.size.width,
                                 scaleY: geo.size.height,
                                 mappings: $mappings,
                                 correctMappings: question.correctMappings)
                }
            }
        }
    }
}

struct DropLocation: View {
    @Environment(QuizViewModel.self) private var viewModel

    let questionId: Int64?
    let dragItems: [DTO.DragItem]
    let location: DTO.DropLocation
    let scaleX: CGFloat
    let scaleY: CGFloat

    @State private var selected = false
    @Binding var mappings: [DTO.DragAndDropMappingFromLiveClient]
    let correctMappings: [DTO.DragAndDropMapping]?

    var body: some View {
        // Positions are scaled from 0...200
        let startX = (location.posX ?? 0) / 200 * scaleX
        let startY = (location.posY ?? 0) / 200 * scaleY
        let width = (location.width ?? 0) / 200 * scaleX
        let height = (location.height ?? 0) / 200 * scaleY

        Group {
            if viewModel.hasSubmitted {
                locationContent(width: width, height: height)
                    .foregroundStyle(.primary)
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(selectedItem != nil ? .isSelected : [])
            } else {
                Button {
                    if mappings.first(where: { $0.dropLocation?.id == location.id })?.dragItem?.id == nil {
                        selected = true
                    } else {
                        updateMapping(selectedRef: nil)
                    }
                } label: { locationContent(width: width, height: height) }
                .disabled(viewModel.locksAnswerEditing)
            }
        }
        .popover(isPresented: $selected, attachmentAnchor: .point(.bottom), arrowEdge: .top) {
            DragItemPicker(questionId: questionId,
                           items: unusedItems,
                           onSelect: updateMapping(selectedRef:))
                .presentationCompactAdaptation(.popover)
        }
        .frame(width: width, height: height)
        .position(x: startX + width / 2,
                  y: startY + height / 2)
    }

    private func locationContent(width: CGFloat, height: CGFloat) -> some View {
            Rectangle()
                .strokeBorder(style: .init(dash: [5]))
                .background {
                    if viewModel.hasSubmitted, let isCorrect {
                        isCorrect ? Color.green : Color.red
                    } else {
                        Color.blue.opacity(selected ? 0.5 : 0.05)
                    }
                }
                .animation(.default, value: selected)
                .frame(width: width, height: height)
                .overlay {
                    if let selectedItem {
                        DragItemView(questionId: questionId, item: selectedItem)
                    }
                }
    }

    var isCorrect: Bool? {
        QuizDropEvaluation.correct(locationID: location.id, selectedItemID: selectedItem?.id, correctMappings: correctMappings)
    }

    var selectedItem: DTO.DragItem? {
        guard let itemId = mappings.first(where: {
            $0.dropLocation?.id == location.id
        })?.dragItem?.id else {
            return nil
        }
        return dragItems.first(where: { $0.id == itemId })
    }

    var unusedItems: [DTO.DragItem] {
        dragItems.filter {
            !mappings.map(\.dragItem?.id).contains($0.id)
        }
    }

    func updateMapping(selectedRef: Int64?) {
        mappings = mappings.map {
            if $0.dragItem?.id == selectedRef && $0.dropLocation?.id == location.id {
                return $0 // Nothing changed
            }
            if $0.dragItem?.id == selectedRef {
                // Unselect old one
                var new = $0
                new.dragItem = nil
                return new
            }
            if $0.dropLocation?.id == location.id {
                // Select new one
                var new = $0
                new.dragItem = .init(id: selectedRef)
                return new
            }
            return $0
        }
        selected = false
    }
}

enum QuizDropEvaluation {
    static func correct(locationID: Int64?, selectedItemID: Int64?, correctMappings: [DTO.DragAndDropMapping]?) -> Bool? {
        guard let correctMappings else { return nil }
        let valid = correctMappings.filter { $0.dropLocation?.id == locationID }
        guard let selectedItemID else { return valid.isEmpty }
        return valid.contains { $0.dragItem?.id == selectedItemID }
    }
}

private struct TrainingQuestionImageWidth: ViewModifier {
    let training: Bool
    func body(content: Content) -> some View {
        if training { content.frame(maxWidth: .infinity) } else { content.containerRelativeFrame(.horizontal) }
    }
}
