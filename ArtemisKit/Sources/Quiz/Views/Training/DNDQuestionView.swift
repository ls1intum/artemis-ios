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

extension DTO.QuizQuestionWithSolution: WithImage {}

struct DNDQuestionView: View {
    let question: DTO.QuizQuestionTraining

    @State private var imageSize: CGSize?

    @State private var mappings: [DTO.DragAndDropMappingFromLiveClient]

    var backgroundImage: URL? {
        question.quizQuestionWithSolutionDTO.image(for: \.backgroundFilePath)
    }

    init(question: DTO.QuizQuestionTraining) {
        self.question = question
        self.mappings = (question.quizQuestionWithSolutionDTO.dropLocations ?? []).map {
            .init(dragItem: nil, dropLocation: .init(id: $0.id))
        }
    }

    var body: some View {
        if let text = question.quizQuestionWithSolutionDTO.text {
            Text(text)
                .padding(.horizontal)
        }

        ArtemisAsyncImage(imageURL: backgroundImage) { _ in
        } onSuccess: { img in
            imageSize = img.image.size
        } errorPlaceholder: {
            Text("Failed to load image :/")
        }
        .scaledToFit()
        .containerRelativeFrame(.horizontal)
        .overlay {
            DNDDropLocations(mappings: $mappings, question: question.quizQuestionWithSolutionDTO, imageSize: imageSize)
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

    let question: DTO.QuizQuestionWithSolution
    let imageSize: CGSize?

    var body: some View {
        if let imageSize,
           let dropLocations = question.dropLocations,
           let dragItems = question.dragItems {
            GeometryReader { geo in
                let width = geo.size.width * 2 // Web app also has the factor of two
                let height = geo.size.height * 1.25 // Don't ask.

                let scaleX = imageSize.width / width
                let scaleY = imageSize.height / height

                ForEach(dropLocations, id: \.id) { location in
                    DropLocation(dragItems: dragItems,
                                 location: location,
                                 scaleX: scaleX,
                                 scaleY: scaleY,
                                 mappings: $mappings)
                }
            }
        }
    }
}

struct DropLocation: View {
    let dragItems: [DTO.DragItem]
    let location: DTO.DropLocation
    let scaleX: CGFloat
    let scaleY: CGFloat

    @State private var selected = false
    @Binding var mappings: [DTO.DragAndDropMappingFromLiveClient]

    var body: some View {
        let startX = (location.posX ?? 0) / scaleX
        let startY = (location.posY ?? 0) / scaleY
        let width = (location.width ?? 0) / scaleX
        let height = (location.height ?? 0) / scaleY

        Button {
            if mappings.first(where: { $0.dropLocation?.id == location.id })?.dragItem?.id == nil {
                selected = true
            } else {
                updateMapping(selectedRef: nil)
            }
        } label: {
            Rectangle()
                .strokeBorder(style: .init(dash: [5]))
                .background(Color.blue.opacity(selected ? 0.5 : 0.05))
                .animation(.default, value: selected)
                .frame(width: width, height: height)
                .overlay {
                    if let itemId = mappings.first(where: { $0.dropLocation?.id == location.id })?.dragItem?.id,
                       let item = dragItems.first(where: { $0.id == itemId }) {
                        DragItemView(item: item)
                    }
                }
        }
        .popover(isPresented: $selected, attachmentAnchor: .point(.bottom), arrowEdge: .top) {
            DragItemPicker(items: unusedItems,
                           onSelect: updateMapping(selectedRef:))
                .presentationCompactAdaptation(.popover)
        }
        .frame(width: width, height: height)
        .position(x: startX + width / 2,
                  y: startY + height / 2)
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
