//
//  File.swift
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

    private let messagesService: MessagesService

    var error: UserFacingError? {
        switch uploadState {
        case .failed(let error):
            return error
        default:
            return nil
        }
    }

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
        loadTransferable(from: selection)
    }

    private func loadTransferable(from item: PhotosPickerItem?) {
        guard let item else {
            return
        }

        uploadState = .compressing
        filePath = nil

        Task {
            if let transferable = try? await item.loadTransferable(type: Data.self) {
                image = UIImage(data: transferable)
                upload(image: image)
            }
        }
    }

    private func upload(image: UIImage?) {
        guard let image else { return }

        guard let imageData = compressImageBelow5MB(image) else {
            uploadState = .failed(error: .init(title: "Image too large. Plese select a smaller image."))
            return
        }

        uploadState = .uploading

        uploadTask = Task {
            let result = await messagesService.uploadImage(for: courseId, and: conversationId, image: imageData)
            if Task.isCancelled {
                return
            }

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
        }
    }

    private func compressImageBelow5MB(_ image: UIImage, level: Double = 1) -> Data? {
        guard let imageData = image.jpegData(compressionQuality: level) else {
            return nil
        }

        // Too much compression needed to be useful
        if level < 0.3 {
            return nil
        }

        if imageData.count > 5 * 1024 * 1024 {
            return compressImageBelow5MB(image, level: level - 0.2)
        } else {
            return imageData
        }
    }
}
