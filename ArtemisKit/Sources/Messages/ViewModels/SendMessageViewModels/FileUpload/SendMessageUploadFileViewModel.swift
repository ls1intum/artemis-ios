//
//  SendMessageUploadFileViewModel.swift
//  ArtemisKit
//
//  Created by Eylul Naz Can on 9.12.2024.
//

import Foundation
import UniformTypeIdentifiers
import Common
import SwiftUI

@Observable
final class SendMessageUploadFileViewModel: UploadViewModel {

    var fileData: Data?
    var fileName: String?
    var isFilePickerPresented = false

    private let messagesService: MessagesService

    let allowedFileTypes: [UTType] = [
        .png,
        .jpeg,
        .gif,
        .svg,
        .pdf,
        .rtf,
        .plainText,
        .json,
        .spreadsheet,
        .presentation,
        UTType(filenameExtension: "doc") ?? .data,
        UTType(filenameExtension: "docx") ?? .data,
        UTType(filenameExtension: "xls") ?? .spreadsheet,
        UTType(filenameExtension: "xlsx") ?? .spreadsheet,
        UTType(filenameExtension: "ppt") ?? .presentation,
        UTType(filenameExtension: "pptx") ?? .presentation
    ]

    init(
        courseId: Int,
        conversationId: Int64,
        messagesService: MessagesService = MessagesServiceFactory.shared
    ) {
        self.messagesService = messagesService
        super.init(courseId: courseId, conversationId: conversationId)
    }

    /// Handles changes to the selected file URL
    func filePicked(at url: URL) {
        isFilePickerPresented = false
        loadFileData(from: url)
    }

    /// Reads the file data from the provided URL
    private func loadFileData(from url: URL) {
        uploadState = .compressing
        filePath = nil

        Task {
            do {
                guard url.startAccessingSecurityScopedResource() else {
                    throw NSFileProviderError(.notAuthenticated)
                }
                let fileData = try Data(contentsOf: url)
                url.stopAccessingSecurityScopedResource()
                let fileName = url.lastPathComponent
                handleFileSelection(fileData: fileData, fileName: fileName)
            } catch {
                uploadState = .failed(error: .init(title: "Failed to read the selected file. Please try again."))
            }
        }
    }

    /// Validates and handles the selected file data
    private func handleFileSelection(fileData: Data, fileName: String) {
        self.fileData = fileData
        self.fileName = fileName

        if fileData.count > 5 * 1024 * 1024 {
            uploadState = .failed(
                error: .init(title: "The file size exceeds the 5MB limit. Please choose a smaller file.")
            )
            return
        }

        let fileExtension = (fileName as NSString).pathExtension.lowercased()
        guard allowedFileTypes.contains(where: { $0.preferredFilenameExtension == fileExtension }) else {
            uploadState = .failed(
                error: .init(title: "The file type '\(fileExtension)' is not supported.")
            )
            return
        }

        upload(data: fileData, fileName: fileName, mimeType: fileExtension)
    }

    private func upload(data: Data, fileName: String, mimeType: String) {
        uploadState = .uploading

        uploadTask = Task {
            let result = await messagesService.uploadFile(for: courseId, and: conversationId, file: data, filename: fileName, mimeType: mimeType)
            if Task.isCancelled { return }

            switch result {
            case .loading:
                break
            case .failure(let error):
                uploadState = .failed(error: error)
            case .done(let response):
                filePath = response
                uploadState = .done
            }
        }
    }

    func resetFileSelection() {
        fileData = nil
        fileName = nil
    }
}
