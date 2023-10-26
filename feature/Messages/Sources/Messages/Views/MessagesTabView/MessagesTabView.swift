//
//  MessagesTabView.swift
//
//
//  Created by Nityananda Zbil on 26.10.23.
//

import APIClient
import Common
import DesignLibrary
import SharedModels
import SwiftUI

public struct MessagesTabView: View {

    @EnvironmentObject private var messagesPreferences: MessagesPreferences

    @StateObject private var viewModel: MessagesTabViewModel

    @Binding private var searchText: String

    public init(course: Course, searchText: Binding<String>) {
        self._viewModel = StateObject(wrappedValue: MessagesTabViewModel(course: course))
        self._searchText = searchText
    }

    public var body: some View {
        DataStateView(data: $viewModel.codeOfConduct) {
            await viewModel.getCodeOfConductInformation()
        } content: { codeOfConduct in
            if viewModel.codeOfConductAgreement.value ?? false {
                MessagesAvailableView(course: viewModel.course, searchText: _searchText)
            } else {
                CodeOfConductView(codeOfConduct: codeOfConduct,
                                  responsibleUsers: viewModel.codeOfConductResonsibleUsers.value ?? []) {
                    await viewModel.acceptCodeOfConduct()
                }
            }
        }
        .task {
            await viewModel.getCodeOfConductInformation()
        }
        .onChange(of: viewModel.codeOfConductAgreement.value) {
            messagesPreferences.isSearchable = viewModel.isSearchable
        }
    }
}
