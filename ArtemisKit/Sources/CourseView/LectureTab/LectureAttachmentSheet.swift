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

    let attachment: Attachment?
    var lectureId: Int?
    var lectureName: String?

    @State private var previewURL: DataState<URL> = .loading

    var body: some View {
        DataStateView(data: $previewURL,
                      retryHandler: {
            if let lectureId, let lectureName {
                await loadAttachment(lectureId: lectureId, lectureName: lectureName)
            } else {
                await loadAttachment()
            }
        }) { url in
            QuickLookController(url: url)
        }
        .task {
            if let lectureId, let lectureName {
                await loadAttachment(lectureId: lectureId, lectureName: lectureName)
            } else {
                await loadAttachment()
            }
        }
    }

    private func loadAttachment() async {
        let fileName: String? = attachment?.name

        guard let link = attachment?.link else {
            previewURL = .failure(error: UserFacingError(title: "There is no download link for this attachment!"))
            return
        }

        let normalizedLink = link.hasPrefix("/api/core/files/") ? link : "/api/core/files/\(link)"
        previewURL = await LectureServiceFactory.shared.getAttachmentFile(link: normalizedLink, name: fileName)
    }

    private func loadAttachment(lectureId: Int, lectureName: String) async {
        let normalizedLink = "/api/core/files/attachments/lecture/\(lectureId)/merge-pdf"
        previewURL = await LectureServiceFactory.shared.getAttachmentFile(link: normalizedLink, name: lectureName)
    }
}

struct AttachmentUnitSheetContent: View {

    let attachmentUnit: AttachmentVideoUnit?
    var lectureId: Int?
    var lectureName: String?

    @State private var showAttachment = false

    var body: some View {
        if let lectureId, let lectureName {
            LectureAttachmentSheet(attachment: nil, lectureId: lectureId, lectureName: lectureName)
        } else if let attachment = attachmentUnit?.attachment, attachmentUnit?.videoSource == nil {
            // Only attachment -> Make it full screen
            LectureAttachmentSheet(attachment: attachment)
        } else {
            ScrollView {
                if let attachment = attachmentUnit?.attachment {
                    NavigationLink {
                        LectureAttachmentSheet(attachment: attachment)
                    } label: {
                        BaseLectureUnitCell(viewModel: .init(courseId: nil, lectureId: nil),
                                            lectureUnit: .attachmentVideo(lectureUnit: attachmentUnit!))
                        .padding(.horizontal)
                        .allowsHitTesting(false)
                    }
                    .foregroundStyle(.primary)
                }
                if let videoSource = attachmentUnit?.videoSource,
                   let videoUrl = URL(string: videoSource) {
                    VideoUnitSheetContent(unit: attachmentUnit!, videoSource: videoUrl)
                } else {
                    Text(R.string.localizable.attachmentCouldNotBeOpened())
                        .foregroundColor(.red)
                }
            }
        }
    }
}
