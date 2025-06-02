//
//  ProposeFaqButton.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 02.06.25.
//

import SwiftUI

struct ProposeFaqButton: View {
    @Bindable var viewModel: FaqViewModel

    var body: some View {
        if viewModel.canPropose {
            Button {
                viewModel.showProposalView = true
            } label: {
                Image(systemName: "square.and.pencil")
                    .foregroundStyle(.white)
                    .font(.title2)
                    .padding()
                    .background(Color.Artemis.artemisBlue, in: .circle)
                    .shadow(color: Color.gray.opacity(0.2), radius: .m)
            }
            .sheet(isPresented: $viewModel.showProposalView) {
                viewModel.proposedFaq = .init()
            } content: {
                ProposeFaqView(viewModel: viewModel)
            }
        }
    }
}
