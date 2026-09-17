//
//  DragItemViews.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 07.06.26.
//

import DesignLibrary
import Extensions
import SharedModels
import SwiftUI

extension DTO.DragItem: WithImage {}

struct DragItemPicker: View {
    let questionId: Int64?
    let items: [DTO.DragItem]
    let onSelect: (Int64?) -> Void

    var body: some View {
        ScrollView {
            VStack {
                ForEach(items, id: \.id) { item in
                    Button {
                        onSelect(item.id)
                    } label: {
                        DragItemView(questionId: questionId, item: item)
                    }
                }
            }
            .frame(minWidth: 200)
        }
        .contentMargins(.all, .l, for: .scrollContent)
        .frame(minHeight: 200)
    }
}

struct DragItemView: View {
    let questionId: Int64?
    let item: DTO.DragItem

    var body: some View {
        if let expandedImageUrl {
            ArtemisAsyncImage(imageURL: expandedImageUrl) {}
                .scaledToFit()
        } else if let text = item.text {
            Text(text)
                .minimumScaleFactor(0.5)
                .padding()
                .background(.background)
                .border(.primary)
        }
    }

    private var expandedImageUrl: URL? {
        guard let imageUrl = item.image(for: \.pictureFilePath) else { return nil }
        guard let questionId else { return imageUrl }
        let string = imageUrl.absoluteString
            .replacing("drag-and-drop/drag-items",
                       with: "drag-and-drop/questions/\(questionId)/drag-items")
        return URL(string: string)
    }
}
