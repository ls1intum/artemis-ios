//
//  ForceAppUpdate.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 10.02.25.
//

import SwiftUI

struct ForceAppUpdateViewModifier: ViewModifier {
    @Binding var updateRequirement: UpdateRequirement

    private var presentUpdateSheet: Binding<Bool> {
        Binding(
            get: {
                updateRequirement != .upToDate
            },
            set: { newValue in
                if !newValue {
                    updateRequirement = .upToDate
                }
            }
        )
    }

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: presentUpdateSheet) {
                UpdateAvailableView(updateRequirement: updateRequirement)
                    .interactiveDismissDisabled()
            }
    }
}

private struct UpdateAvailableView: View {
    @Environment(\.openURL) var openURL
    @Environment(\.dismiss) var dismiss
    let updateRequirement: UpdateRequirement

    var body: some View {
        ScrollView {
            VStack(spacing: .xl) {
                Image(systemName: "app.badge.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundStyle(.blue)
                    .padding(.top)

                Text(R.string.localizable.updateAvailable())
                    .font(.title.bold())

                Text(R.string.localizable.updateDescription())
                    .multilineTextAlignment(.center)
            }
        }
        .contentMargins(.xl, for: .scrollContent)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 20) {
                Button {
                    if let url = URL(string: "https://apps.apple.com/app/artemis-learning/id6478965616") {
                        openURL(url)
                    }
                } label: {
                    Text(R.string.localizable.download())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, .m)
                }
                .buttonStyle(.borderedProminent)

                if updateRequirement == .recommendsUpdate {
                    Button(R.string.localizable.notNow()) {
                        dismiss()
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(.bar)
        }
    }
}
