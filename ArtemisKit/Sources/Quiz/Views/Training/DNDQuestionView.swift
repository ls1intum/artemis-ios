//
//  DNDQuestionView.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 07.06.26.
//

import DesignLibrary
import Extensions
import SharedModels
import SwiftUI

extension DTO.DragAndDropQuizQuestionWithSolution: WithImage {}

struct DNDQuestionView: View {
    let question: DTO.QuizQuestionTraining
    let questionWithAnswer: DTO.DragAndDropQuizQuestionWithSolution

    @State private var mappings: [DTO.DragAndDropMappingFromLiveClient]

    var backgroundImage: URL? {
        questionWithAnswer.image(for: \.backgroundFilePath)
    }

    init(question: DTO.QuizQuestionTraining, questionWithAnswer: DTO.DragAndDropQuizQuestionWithSolution) {
        self.question = question
        self.questionWithAnswer = questionWithAnswer
        self.mappings = (questionWithAnswer.dropLocations ?? []).map {
            .init(dragItem: nil, dropLocation: .init(id: $0.id))
        }
    }

    var body: some View {
        if let text = questionWithAnswer.text {
            Text(LocalizedStringKey(text))
                .padding(.horizontal)
        }

        ArtemisAsyncImage(imageURL: backgroundImage) {
            Text("Failed to load image :/")
        }
        .scaledToFit()
        .containerRelativeFrame(.horizontal)
        .overlay {
            DNDDropLocations(mappings: $mappings, question: questionWithAnswer)
        }

        Text(R.string.localizable.dndInfo())
            .font(.caption)
            .padding(.horizontal)

        SubmitAnswerButton(questionId: question.id, isRated: question.isRated, answer: answer)
    }

    var answer: QuizTrainingAnswer {
        .DragAndDropSubmittedAnswerFromLiveClient(.init(
            .init(quizQuestion: .init(id: question.id),
                  mappings: mappings))
        )
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
                    DropLocation(dragItems: dragItems,
                                 location: location,
                                 scaleX: geo.size.width,
                                 scaleY: geo.size.height,
                                 mappings: $mappings,
                                 correctMappings: question.correctMappings ?? [])
                }
            }
        }
    }
}

struct DropLocation: View {
    @Environment(QuizTrainingViewModel.self) private var viewModel

    let dragItems: [DTO.DragItem]
    let location: DTO.DropLocation
    let scaleX: CGFloat
    let scaleY: CGFloat

    @State private var selected = false
    @Binding var mappings: [DTO.DragAndDropMappingFromLiveClient]
    let correctMappings: [DTO.DragAndDropMapping]

    var body: some View {
        // Positions are scaled from 0...200
        let startX = (location.posX ?? 0) / 200 * scaleX
        let startY = (location.posY ?? 0) / 200 * scaleY
        let width = (location.width ?? 0) / 200 * scaleX
        let height = (location.height ?? 0) / 200 * scaleY

        Button {
            if mappings.first(where: { $0.dropLocation?.id == location.id })?.dragItem?.id == nil {
                selected = true
            } else {
                updateMapping(selectedRef: nil)
            }
        } label: {
            Rectangle()
                .strokeBorder(style: .init(dash: [5]))
                .background {
                    if viewModel.hasSubmitted {
                        isCorrect ? Color.green : Color.red
                    } else {
                        Color.blue.opacity(selected ? 0.5 : 0.05)
                    }
                }
                .animation(.default, value: selected)
                .frame(width: width, height: height)
                .overlay {
                    if let selectedItem {
                        DragItemView(item: selectedItem)
                    }
                }
        }
        .allowsHitTesting(!viewModel.hasSubmitted)
        .popover(isPresented: $selected, attachmentAnchor: .point(.bottom), arrowEdge: .top) {
            DragItemPicker(items: unusedItems,
                           onSelect: updateMapping(selectedRef:))
                .presentationCompactAdaptation(.popover)
        }
        .frame(width: width, height: height)
        .position(x: startX + width / 2,
                  y: startY + height / 2)
    }

    var isCorrect: Bool {
        let mapping = correctMappings.first { $0.dropLocation?.id == location.id }
        return mapping?.dragItem?.id == selectedItem?.id
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
