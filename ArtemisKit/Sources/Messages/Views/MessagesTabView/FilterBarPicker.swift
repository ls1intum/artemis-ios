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
        HStack(spacing: .m) {
            ForEach(Array(Filter.allCases)) { filter in
                Button {
                    selectedFilter = filter
                } label: {
                    item(for: filter)
                        .frame(height: 40)
                        .id(filter)
                }
                .buttonStyle(.plain)
            }
        }
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
        .animation(.smooth(duration: 0.2), value: selectedFilter)
    }

    @ViewBuilder
    func item(for filter: Filter) -> some View {
        HStack(alignment: .center) {
            Image(systemName: filter.iconName)
                .symbolVariant(filter == selectedFilter ? .fill : .none)
                .font(.title3)
                .foregroundStyle(filter == selectedFilter ? .primary : .secondary)

            if filter == selectedFilter {
                Text(filter.displayName)
                    .font(.headline)
            }
        }
        .accessibilityLabel(filter.displayName)
        .padding(.horizontal, .l + .s)
        .frame(maxWidth: filter == selectedFilter ? .infinity : nil, maxHeight: .infinity)
        .background(
            filter == selectedFilter ? filter.selectedColor.opacity(0.5) : .gray.opacity(0.3),
            in: .rect(cornerRadius: .l)
        )
    }
}

protocol FilterPicker: CaseIterable, Identifiable, Hashable {
    var displayName: String { get }
    var iconName: String { get }
    var selectedColor: Color { get }
}
