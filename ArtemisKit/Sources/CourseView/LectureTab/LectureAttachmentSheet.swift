//
//  LectureAttachmentSheet.swift
//  
//
//  Created by Sven Andabaka on 30.04.23.
//

import SwiftUI
import SharedModels
import DesignLibrary
import Common

struct LectureAttachmentSheet: View {

    let attachment: Attachment

    @State private var previewURL: DataState<URL> = .loading

    var body: some View {
        DataStateView(data: $previewURL,
                      retryHandler: { await loadAttachment() }) { url in
            QuickLookController(url: url)
        }
            .task {
                await loadAttachment()
            }
    }

    private func loadAttachment() async {
        let fileName: String? = attachment.name

        guard let link = attachment.link else {
            previewURL = .failure(error: UserFacingError(title: "There is no download link for this attachment!"))
            return
        }

        let normalizedLink = link.hasPrefix("/api/core/files/") ? link : "/api/core/files/\(link)"
        previewURL = await LectureServiceFactory.shared.getAttachmentFile(link: normalizedLink, name: fileName)
    }
}
