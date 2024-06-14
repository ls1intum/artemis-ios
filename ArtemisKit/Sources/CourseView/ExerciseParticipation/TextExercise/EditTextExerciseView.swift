//
//  EditTextExerciseView.swift
//
//
//  Created by Nityananda Zbil on 10.12.23.
//

import DesignLibrary
import SwiftUI

public struct EditTextExerciseView: View {

    @State var viewModel: EditTextExerciseViewModel = .init()

    public init() {}

    public var body: some View {
        VStack(alignment: .leading) {
            TextEditor(text: $viewModel.text)
                .overlay {
                    // Corner radius of segmented picker.
                    RoundedRectangle(cornerRadius: 9)
                        .stroke(Color.Artemis.artemisBlue)
                }
        }
        .padding([.horizontal, .bottom])
        .onChange(of: viewModel.text) {
            viewModel.isSubmitted = false
        }
        .navigationTitle("Exercise")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem {
                HStack {
                    Button {
                        //
                    } label: {
                        Image(systemName: "newspaper")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(.white)
                            .font(.headline)
                            .padding(.vertical, .m)
                            .padding(.horizontal, .l)
                            .background {
                                RoundedRectangle(cornerRadius: 4)
                                    .foregroundColor(Color.Artemis.primaryButtonColor)
                            }
                    }
                    Button("Submit") {
                        viewModel.isSubmitted = true
                    }
                    .buttonStyle(ArtemisButton())
                    .disabled(viewModel.isSubmitted)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        EditTextExerciseView()
    }
}
