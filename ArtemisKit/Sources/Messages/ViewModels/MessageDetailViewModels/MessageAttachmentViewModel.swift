//
//  MessageAttachmentViewModel.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 24.12.24.
//

import Common
import Foundation

@Observable
class MessageAttachmentViewModel {
    private let url: URL
    var attachmentUrl: DataState<URL> = .loading

    init(url: URL) {
        self.url = url
    }

    func loadAttachmentUrl() async {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)

            let suggestedFilename = url.lastPathComponent
            let previewURL = FileManager.default.temporaryDirectory.appendingPathComponent(suggestedFilename)
            try data.write(to: previewURL, options: .atomic)   // atomic option overwrites it if needed
            attachmentUrl = .done(response: previewURL)
        } catch {
            attachmentUrl = .failure(error: UserFacingError(title: error.localizedDescription))
        }
    }
}
