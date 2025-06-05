//
//  CategoriesView.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 28.05.25.
//

import DesignLibrary
import SharedModels
import SwiftUI

struct CategoriesView: View {
    let categories: [FaqCategory]

    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(categories, id: \.category) { category in
                    Chip(text: category.category, backgroundColor: .init(uiColor: category.uiColor))
                }
            }
        }
        .scrollClipDisabled()
    }
}
