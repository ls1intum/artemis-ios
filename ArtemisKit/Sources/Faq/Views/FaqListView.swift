//
//  FaqListView.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 24.10.24.
//

import ArtemisMarkdown
import Common
import DesignLibrary
import Navigation
import SharedModels
import SwiftUI

public struct FaqListView: View {
    @Namespace var namespace
    @Environment(\.horizontalSizeClass) var sizeClass
    @EnvironmentObject var navController: NavigationController
    @State private var columnVisibilty: NavigationSplitViewVisibility = .doubleColumn
    @State var viewModel: FaqViewModel

    private var selectedFaq: Binding<FaqPath?> {
        navController.selectedPathBinding($navController.selectedPath)
    }

    public init(course: Course) {
        self._viewModel = State(initialValue: FaqViewModel(course: course))
    }

    public var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibilty) {
            DataStateView(data: $viewModel.faqs) {
                await viewModel.loadFaq()
            } content: { faqs in
                List(selection: selectedFaq) {
                    if viewModel.searchText.isEmpty {
                        if faqs.isEmpty {
                            ContentUnavailableView(R.string.localizable.noFaqs(), systemImage: "character.book.closed")
                                .listRowSeparator(.hidden)
                        } else {
                            ForEach(faqs) { faq in
                                FaqListCell(faq: faq, namespace: namespace)
                            }
                        }
                    } else {
                        if viewModel.searchResults.isEmpty {
                            ContentUnavailableView.search
                                .listRowSeparator(.hidden)
                        } else {
                            ForEach(viewModel.searchResults) { faq in
                                FaqListCell(faq: faq, namespace: namespace)
                            }
                        }
                    }
                }
                .listRowSpacing(.m)
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .searchable(text: $viewModel.searchText)
                .refreshable {
                    await viewModel.loadFaq()
                }
            }
            .navigationTitle(viewModel.course.title ?? R.string.localizable.faqs())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    BackToRootButton(placement: .navBar, sizeClass: sizeClass)
                }
            }
        } detail: {
            NavigationStack(path: $navController.tabPath) {
                Group {
                    if let path = navController.selectedPath as? FaqPath {
                        FaqPathView(path: path)
                            .id(path.id)
                    } else {
                        SelectDetailView()
                    }
                }
                .navigationDestination(for: FaqPath.self) { path in
                    FaqPathView(path: path)
                }
            }
        }
        .task {
            await viewModel.loadFaq()
        }
    }
}

private struct FaqListCell: View {
    let faq: FaqDTO
    let namespace: Namespace.ID
    @EnvironmentObject var navController: NavigationController

    var body: some View {
        ZStack {
            VStack(alignment: .leading) {
                Text(faq.questionTitle)
                    .font(.title2.bold())
                    .lineLimit(2)
                ArtemisMarkdownView(string: faq.questionAnswer)
                    .frame(minHeight: 70, maxHeight: 150, alignment: .top)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .multilineTextAlignment(.leading)
            .padding(12)

            Button {
                navController.selectedPath = FaqPath(faq: faq, namespace: namespace)
            } label: {
                Text("\(R.string.localizable.readMore()) \(Image(systemName: "chevron.forward"))")
                    .padding(.m)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.top, 30)
            .background(.ultraThinMaterial)
            .mask(
                LinearGradient(
                    gradient: Gradient(
                        colors: [
                            .black.opacity(0),
                            .black.opacity(0.8),
                            .black,
                            .black]
                    ),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .listRowBackground(Color.Artemis.exerciseCardBackgroundColor)
        .listRowInsets(EdgeInsets())
        .id(FaqPath(faq: faq, namespace: namespace))
        .matchedTransitionSource(id: faq.id, in: namespace)
    }
}
