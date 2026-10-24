import SwiftUI

/// Inserts Unicode at the editor's retained selection, using the app's existing emoji catalog.
struct MessageComposerEmojiPicker: View {
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    let insert: (String) -> Void
    private static let commonEmojis = ["😀", "😊", "😂", "🙂", "😉", "😍", "🤔", "👍", "👎", "👋", "🙌", "🎉", "❤️", "🔥", "✅", "🚀"]

    private var results: [String] {
        let search = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let matches = Emojis.all.filter { name, symbol in
            search.isEmpty || name.replacingOccurrences(of: "_", with: " ").localizedCaseInsensitiveContains(search) || symbol.contains(search)
        }
        let first = search.isEmpty ? Self.commonEmojis : []
        return first + Set(matches.values).subtracting(first).sorted()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 8) {
                    ForEach(results, id: \.self) { emoji in
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
                }
                .padding()
            }
            .overlay {
                if results.isEmpty { ContentUnavailableView.search(text: query) }
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
