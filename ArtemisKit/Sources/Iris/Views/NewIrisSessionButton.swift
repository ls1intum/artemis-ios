//
//  NewIrisSessionButton.swift
//  ArtemisKit
//
//  Created by Senan Aslan on 26.05.26.
//

import Navigation
import SwiftUI

struct NewIrisSessionButton: View {
    @EnvironmentObject private var navigationController: NavigationController
    @Bindable var viewModel: IrisSessionListViewModel
    let courseId: Int

    var body: some View {
        Button {
            Task {
                if let newId = await viewModel.createNewSession() {
                    navigationController.selectedPath = IrisSessionPath(
                        id: newId,
                        coursePath: CoursePath(id: courseId)
                    )
                    await viewModel.loadSessions()
                }
            }
        } label: {
            Image(systemName: "plus")
                .foregroundStyle(.white)
                .font(.title2)
                .padding()
                .background(Color.Artemis.artemisBlue, in: .circle)
                .shadow(color: Color.gray.opacity(0.2), radius: .m)
        }
        .disabled(viewModel.isLoading)
    }
}
