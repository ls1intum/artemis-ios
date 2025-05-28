//
//  CategoriesView.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 28.05.25.
//

import DesignLibrary
import SwiftUI

struct CategoriesView: View {
    let categories: Set<String>

    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(categories.compactMap(Category.init(jsonString:)), id: \.category) { category in
                    Chip(text: category.category, backgroundColor: .init(uiColor: category.uiColor))
                }
            }
        }
        .scrollClipDisabled()
    }
}

private struct Category: Codable {
    let color: String
    let category: String

    var uiColor: UIColor {
        UIColor(hexString: color)
    }
}

extension Category {
    init?(jsonString: String) {
        if let decoded = try? JSONDecoder().decode(Self.self, from: Data(jsonString.utf8)) {
            self = decoded
        } else {
            return nil
        }
    }
}
