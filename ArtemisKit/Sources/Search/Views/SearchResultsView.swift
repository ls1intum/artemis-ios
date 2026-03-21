//
//  SearchResultsView.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 21.03.26.
//

import SwiftUI

struct SearchResultsView: View {
    let results: [String]

    var body: some View {
        if results.isEmpty {
            ContentUnavailableView.search
        } else {
            // TODO: Show search results
        }
    }
}
