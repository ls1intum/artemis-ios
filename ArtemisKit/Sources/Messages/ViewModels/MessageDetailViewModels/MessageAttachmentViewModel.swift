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
    var attachmentUrl: Result<URL, UserFacingError>?

    init(url: URL) {
        self.url = url
    }

    func loadAttachmentUrl() async {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)

            let suggestedFilename = url.lastPathComponent
            let previewURL = FileManager.default.temporaryDirectory.appendingPathComponent(suggestedFilename)
            try data.write(to: previewURL, options: .atomic)   // atomic option overwrites it if needed
            attachmentUrl = .success(previewURL)
        } catch {
            attachmentUrl = .failure(UserFacingError(title: error.localizedDescription))
        }
    }
}
