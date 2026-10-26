import MarkdownUI
import SwiftUI
import UIKit

/// Both Markdown image hooks are overridden; neither can fall through to a global loader.
public struct SafeReviewContent: View {
    @Environment(\.reviewAssets) private var assets
    let text: String
    public init(_ text: String) { self.text = text }
    public var body: some View {
        Markdown(text, baseURL: assets?.baseURL, imageBaseURL: assets?.baseURL)
            .markdownTheme(.gitHub)
            .markdownImageProvider(ReviewBlockImageProvider())
            .markdownInlineImageProvider(ReviewInlineImageProvider(assets: assets))
            .textSelection(.enabled)
    }
}

public struct ReviewImage: View {
    @Environment(\.reviewAssets) private var assets
    private let path: String?
    private let filePath: Bool
    @State private var image: UIImage?
    @State private var failed = false
    public init(path: String?, filePath: Bool = false) { self.path = path; self.filePath = filePath }
    public var body: some View {
        Group {
            if let image { Image(uiImage: image).resizable().scaledToFit() } else if failed || path == nil || assets == nil {
                Label {
                    Text("Image unavailable", bundle: .module)
                } icon: { Image(systemName: "photo.badge.exclamationmark") }
                .foregroundStyle(.secondary)
            } else { ProgressView() }
        }
        .task(id: "\(assets?.id.uuidString ?? ""):\(path ?? "")") {
            image = nil; failed = false
            guard let assets, let path else { failed = true; return }
            do {
                let data = try await assets.data(path: path, filePath: filePath)
                guard assets.isCurrent, !Task.isCancelled, let decoded = UIImage(data: data) else { throw ReviewAssetError.invalidImage }
                image = decoded
            } catch { image = nil; failed = true }
        }
        .onDisappear { image = nil }
    }
}

private struct ReviewBlockImageProvider: ImageProvider {
    func makeImage(url: URL?) -> some View { ReviewImage(path: url?.absoluteString).frame(maxWidth: .infinity, maxHeight: 400, alignment: .leading) }
}

private struct ReviewInlineImageProvider: InlineImageProvider {
    let assets: ReviewAssetContext?
    func image(with url: URL, label: String) async throws -> Image {
        guard let assets else { throw ReviewAssetError.unavailable }
        let data = try await assets.data(path: url.absoluteString)
        guard assets.isCurrent, !Task.isCancelled, let image = UIImage(data: data) else { throw ReviewAssetError.invalidImage }
        guard let bitmap = image.cgImage else { throw ReviewAssetError.invalidImage }
        return Image(bitmap, scale: max(image.scale, CGFloat(bitmap.width) / 220), label: Text(label))
    }
}
