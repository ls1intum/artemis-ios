import SwiftUI

/// Inserts Unicode at the editor's retained selection, using the app's existing emoji catalog.
struct MessageComposerEmojiPicker: View {
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    let insert: (String) -> Void
    private var sections: [Emojis.PickerSection] { Emojis.pickerSections(matching: query) }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 8) {
                    ForEach(sections) { section in
                        Section {
                            ForEach(section.emojis, id: \.self) { emoji in
                                Button {
                                    insert(emoji)
                                    dismiss()
                                } label: {
                                    Text(emoji)
                                        .font(.title)
                                        .frame(minWidth: 44, minHeight: 44)
                                        .contentShape(.rect)
                                }
                                .buttonStyle(.plain)
                            }
                        } header: {
                            Text(section.category.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 12)
                                .padding(.bottom, 4)
                                .accessibilityAddTraits(.isHeader)
                        }
                    }
                }
                .padding()
            }
            .overlay {
                if sections.isEmpty { ContentUnavailableView.search(text: query) }
            }
            .searchable(text: $query, prompt: R.string.localizable.searchEmojis())
            .navigationTitle(R.string.localizable.emojis())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(R.string.localizable.cancel()) { dismiss() }
                }
            }
        }
    }
}
