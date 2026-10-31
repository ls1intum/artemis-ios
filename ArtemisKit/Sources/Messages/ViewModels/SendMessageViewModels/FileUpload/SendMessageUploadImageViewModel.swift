//
//  SendMessageUploadImageViewModel.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 09.11.24.
//

import Common
import Foundation
import PhotosUI
import SwiftUI

@Observable
final class SendMessageUploadImageViewModel: UploadViewModel {

    var selection: PhotosPickerItem?
    var image: UIImage?
    var isImagePickerPresented = false

    private let messagesService: MessagesService

    init(
        courseId: Int,
        conversationId: Int64,
        messagesService: MessagesService = MessagesServiceFactory.shared
    ) {
        self.messagesService = messagesService
        super.init(courseId: courseId, conversationId: conversationId)
    }

    /// Register as change handler for selection on View
    func onChange() {
        isImagePickerPresented = false
        loadTransferable(from: selection)
    }

    private func loadTransferable(from item: PhotosPickerItem?) {
        guard let item else {
            return
        }

        loadImage { try await item.loadTransferable(type: Data.self) }
    }

    func loadImage(using loadData: @escaping () async throws -> Data?) {
        uploadTask?.cancel()
        uploadState = .compressing
        filePath = nil
        image = nil

        uploadTask = Task { @MainActor in
            do {
                try Task.checkCancellation()
                let transferable = try await loadData()
                try Task.checkCancellation()
                guard let transferable else { throw ImagePreparationError.invalidImage }

                // Decoding and repeated JPEG compression must not block the UI actor.
                // Forward cancellation because detached tasks do not inherit it.
                let preparation = Task.detached(priority: .userInitiated) {
                    try Self.prepareImage(from: transferable)
                }
                let prepared = try await withTaskCancellationHandler {
                    try await preparation.value
                } onCancel: {
                    preparation.cancel()
                }
                try Task.checkCancellation()
                image = prepared.image
                uploadState = .uploading

                let result = await messagesService.uploadFile(for: courseId, and: conversationId, file: prepared.data,
                                                              filename: "image.jpg", mimeType: "image/jpeg")
                try Task.checkCancellation()

                switch result {
                case .loading:
                    break
                case .failure(let error):
                    uploadState = .failed(error: error)
                case .done(let response):
                    filePath = response
                    uploadState = .done
                }
                selection = nil
            } catch {
                guard !Task.isCancelled else { return }
                uploadState = .failed(error: .init(title: error.localizedDescription))
                selection = nil
            }
        }
    }

    override func cancel() {
        super.cancel()
        selection = nil
        image = nil
    }

    nonisolated private static func prepareImage(from data: Data) throws -> (image: UIImage, data: Data) {
        try Task.checkCancellation()
        guard let image = UIImage(data: data) else { throw ImagePreparationError.invalidImage }

        var quality = 1.0
        while quality >= 0.3 {
            try Task.checkCancellation()
            guard let compressed = image.jpegData(compressionQuality: quality) else { throw ImagePreparationError.invalidImage }
            if compressed.count <= 5 * 1024 * 1024 { return (image, compressed) }
            quality -= 0.2
        }
        throw ImagePreparationError.tooLarge
    }
}

private enum ImagePreparationError: LocalizedError {
    case invalidImage
    case tooLarge

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            R.string.localizable.imageLoadFailed()
        case .tooLarge:
            R.string.localizable.imageTooLarge()
        }
    }
}
