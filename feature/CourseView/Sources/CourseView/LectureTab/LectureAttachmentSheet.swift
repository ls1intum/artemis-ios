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
        var link: String?
        switch attachment {
        case .file(let attachment):
            link = attachment.link
        case .url(let attachment):
            // TODO
            link = nil
        case .unknown:
            link = nil
        }

        guard let link else {
            previewURL = .failure(error: UserFacingError(title: "There is no download link for this attachment!"))
            return
        }

        previewURL = await LectureServiceFactory.shared.getAttachmentFile(link: link)
    }
}
