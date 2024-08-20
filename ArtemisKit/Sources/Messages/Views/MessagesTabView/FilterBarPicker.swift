//
//  FilterBarPicker.swift
//
//
//  Created by Anian Schleyer on 20.08.24.
//

import SwiftUI

struct FilterBarPicker<Filter: FilterPicker>: View {
    @Binding var selectedFilter: Filter

    var body: some View {
        HStack {
            Picker(selection: $selectedFilter) {
                ForEach(Array(Filter.allCases)) { filter in
                    Text(filter.displayName)
                        .tag(filter)
                }
            } label: {
                Text("Filter")
            }
        }
    }
}

protocol FilterPicker: CaseIterable, Identifiable, Hashable {
    var displayName: String { get }
}
