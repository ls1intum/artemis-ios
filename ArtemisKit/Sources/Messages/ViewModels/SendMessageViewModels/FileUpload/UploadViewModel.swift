//
//  UploadState.swift
//  ArtemisKit
//
//  Created by Eylul Naz Can on 9.12.2024.
//

import Common
import Foundation
import SwiftUI

enum UploadState: Equatable {
    case idle
    case compressing
    case uploading
    case done
    case failed(error: UserFacingError)
}

@Observable
class UploadViewModel {
    var uploadState: UploadState = .idle
    var filePath: String?

    private(set) var courseId: Int
    private(set) var conversationId: Int64

    internal var uploadTask: Task<(), Never>?

    init(courseId: Int, conversationId: Int64) {
        self.courseId = courseId
        self.conversationId = conversationId
    }

    var isUploading: Bool { uploadState == .compressing || uploadState == .uploading }

    var showUploadScreen: Binding<Bool> {
        .init {
            self.uploadState != .idle
        } set: { newValue in
            // Dismissing the system picker can transiently dismiss this sheet as it
            // takes over presentation. That must not erase an in-flight upload.
            if !newValue && !self.isUploading {
                self.uploadState = .idle
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
        case .idle:
            return ""
        case .compressing:
            return R.string.localizable.loading()
        case .uploading:
            return R.string.localizable.uploading()
        case .done:
            return R.string.localizable.done()
        case .failed(let error):
            return error.localizedDescription
        }
    }

    func cancel() {
        uploadTask?.cancel()
        uploadTask = nil
        uploadState = .idle
        filePath = nil
    }
}
