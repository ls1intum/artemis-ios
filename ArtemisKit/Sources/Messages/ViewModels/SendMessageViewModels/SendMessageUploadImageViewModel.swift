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

enum UploadState: Equatable {
    case selectImage
    case compressing
    case uploading
    case done
    case failed(error: UserFacingError)
}

@Observable
final class SendMessageUploadImageViewModel {

    let courseId: Int
    let conversationId: Int64

    var selection: PhotosPickerItem?
    var image: UIImage?
    var uploadState = UploadState.selectImage
    var imagePath: String?
    private var uploadTask: Task<(), Never>?

    var showUploadScreen: Binding<Bool> {
        .init {
            self.uploadState != .selectImage
        } set: { newValue in
            if !newValue {
                self.uploadState = .selectImage
            }
        }
    }
    var error: UserFacingError? {
        switch uploadState {
        case .failed(let error):
            return error
        default:
            return nil
        }
    }

    var statusLabel: String {
        switch uploadState {
        case .selectImage:
            ""
        case .compressing:
            R.string.localizable.loading()
        case .uploading:
            R.string.localizable.uploading()
        case .done:
            R.string.localizable.done()
        case .failed(let error):
            error.localizedDescription
        }
    }

    private let messagesService: MessagesService

    init(
        courseId: Int,
        conversationId: Int64,
        messagesService: MessagesService = MessagesServiceFactory.shared
    ) {
        self.courseId = courseId
        self.conversationId = conversationId
        self.messagesService = messagesService
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
        imagePath = nil

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
                imagePath = response
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

    func cancel() {
        uploadTask?.cancel()
        uploadTask = nil
        selection = nil
        image = nil
        uploadState = .selectImage
    }
}
