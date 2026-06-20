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
    let items: [DTO.DragItem]
    let onSelect: (Int64?) -> Void

    var body: some View {
        ScrollView {
            VStack {
                ForEach(items, id: \.id) { item in
                    Button {
                        onSelect(item.id)
                    } label: {
                        DragItemView(item: item)
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
    let item: DTO.DragItem

    var body: some View {
        if let imageUrl = item.image(for: \.pictureFilePath) {
            ArtemisAsyncImage(imageURL: imageUrl) {}
                .scaledToFit()
        } else if let text = item.text {
            Text(text)
                .minimumScaleFactor(0.5)
                .padding()
                .background(.background)
                .border(.primary)
        }
    }
}
