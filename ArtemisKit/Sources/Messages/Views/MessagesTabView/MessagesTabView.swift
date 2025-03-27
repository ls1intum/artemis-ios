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

    @StateObject private var viewModel: MessagesTabViewModel

    public init(course: Course) {
        self._viewModel = StateObject(wrappedValue: MessagesTabViewModel(course: course))
    }

    public var body: some View {
        DataStateView(data: $viewModel.codeOfConductAgreement) {
            await viewModel.getCodeOfConductInformation()
        } content: { agreement in
            if agreement {
                MessagesAvailableView(course: viewModel.course)
            } else {
                ScrollView {
                    CodeOfConductView(course: viewModel.course)
                    HStack {
                        Spacer()
                        Button {
                            Task {
                                await viewModel.acceptCodeOfConduct()
                            }
                        } label: {
                            Text(R.string.localizable.acceptCodeOfConductButtonLabel())
                        }
                        .buttonStyle(ArtemisButton())
                        Spacer()
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .contentMargins(.l, for: .scrollContent)
            }
        }
        .task {
            await viewModel.getCodeOfConductInformation()
        }
    }
}
