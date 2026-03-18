//
//  SearchTabView.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 18.03.26.
//

import Notifications
import SwiftUI

public struct SearchTabView: View {
    @State private var searchTerm = ""
    @State private var scope: SearchScope = .course

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                Section("Search") {
                    Picker(selection: $scope) {
                        ForEach(SearchScope.allCases, id: \.self) { scope in
                            Text(scope.title)
                                .tag(scope)
                        }
                    } label: {
                        Text("Scope")
                    }
                    .controlSize(.large)
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }

                ScopeSuggestion(title: "Ask Iris", image: "eyes.inverse", color: .blue)
                ScopeSuggestion(title: "Exercises", image: "list.bullet.clipboard.fill", color: .orange)
                ScopeSuggestion(title: "Lectures", image: "character.book.closed.fill", color: .orange)
            }
            .searchable(text: $searchTerm)
            .listRowSpacing(15)
            .courseToolbar()
        }
    }
}

private struct ScopeSuggestion: View {
    let title: String
    let image: String
    let color: Color

    var body: some View {
        Button {
            
        } label: {
            ZStack {
                Text(title)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .font(.title)
                Image(systemName: image)
                    .resizable()
                    .scaledToFit()
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .opacity(0.3)
            }
            .frame(height: 80)
        }
        .buttonStyle(.plain)
        .listRowBackground(color.opacity(0.5))
    }
}
