import SwiftUI
import SharedModels
import DesignLibrary
import Common
import UserStore

struct LectureAttachmentSheet: View {
    let attachment: Attachment?
    var lectureId: Int?
    var lectureName: String?
    var identity: String = "attachment"
    var explicitPage: Int?
    var originalSlideNumber: Int?
    var visibleSlideNumbers: [Int]?
    var studentVersion: String?

    @ObservedObject private var session = UserSessionFactory.shared
    @State private var snapshot = LectureMediaSession.capture()
    @State private var previewURL: DataState<LectureAttachmentFile> = .loading
    @State private var resolvedPage: Int?
    @State private var generation = LectureMediaLoadGeneration()

    var body: some View {
        DataStateView(data: $previewURL, retryHandler: { await loadAttachment() }) { file in
            let url = file.url
            if url.pathExtension.lowercased() == "pdf" {
                LecturePDFReader(url: url, explicitPage: resolvedPage, progress: snapshot?.progress(identity: identity + (file.studentVersion ? "/student" : "/original")), requiresExactPage: originalSlideNumber != nil)
            } else {
                QuickLookController(url: url)
            }
        }
        .task { await loadAttachment() }
        .onDisappear {
            generation.cancel()
            removeTemporaryPreview(previewURL)
        }
        .onReceive(session.objectWillChange) { _ in
            Task { @MainActor in
                await Task.yield()
                if snapshot?.isCurrent != true {
                    generation.cancel()
                    removeTemporaryPreview(previewURL)
                    previewURL = .failure(error: UserFacingError(title: LectureMediaError.sessionChanged.localizedDescription))
                }
            }
        }
    }

    private func loadAttachment() async {
        let request = generation.begin()
        guard let snapshot, snapshot.isCurrent else {
            previewURL = .failure(error: UserFacingError(title: LectureMediaError.sessionChanged.localizedDescription))
            return
        }
        removeTemporaryPreview(previewURL)
        previewURL = .loading
        var result: DataState<LectureAttachmentFile>
        if let lectureId, let lectureName {
            result = await LectureServiceFactory.shared.getAttachmentFile(link: "/api/core/files/attachments/lectures/\(lectureId)/merge-pdf", name: lectureName)
        } else if let link = studentVersion ?? attachment?.link, !link.isEmpty {
            // Preserve absolute links for origin validation in the authenticated loader.
            let normalized = link.hasPrefix("/api/core/files/") || URL(string: link)?.scheme != nil ? link : "/api/core/files/\(link)"
            result = await LectureServiceFactory.shared.getAttachmentFile(link: normalized, name: attachment?.name)
        } else {
            result = .failure(error: UserFacingError(title: "There is no download link for this attachment."))
        }
        if studentVersion != nil, case .done(let file) = result {
            result = .done(response: LectureAttachmentFile(url: file.url, studentVersion: true))
        }
        guard !Task.isCancelled, generation.accepts(request) else {
            removeTemporaryPreview(result)
            return
        }
        guard snapshot.isCurrent else {
            removeTemporaryPreview(result)
            previewURL = .failure(error: UserFacingError(title: LectureMediaError.sessionChanged.localizedDescription))
            return
        }
        resolvedPage = explicitPage
        if let originalSlideNumber, case .done(let file) = result {
            guard let page = LectureMediaSlidePage.page(original: originalSlideNumber, visibleNumbers: visibleSlideNumbers ?? [], studentVersion: file.studentVersion) else {
                removeTemporaryPreview(result)
                previewURL = .failure(error: UserFacingError(title: "The referenced slide is unavailable."))
                return
            }
            resolvedPage = page
        }
        previewURL = result
    }
    private func removeTemporaryPreview(_ state: DataState<LectureAttachmentFile>) {
        guard case .done(let file) = state else { return }
        let directory = file.url.deletingLastPathComponent()
        guard directory.lastPathComponent.hasPrefix("lecture-media-") else { return }
        try? FileManager.default.removeItem(at: directory)
    }

}

struct AttachmentUnitSheetContent: View {
    let attachmentUnit: AttachmentVideoUnit?
    var lectureId: Int?
    var lectureName: String?
    var identity: String = "attachment"
    var explicitPage: Int?
    var originalSlideNumber: Int?
    var visibleSlideNumbers: [Int]?
    var studentVersion: String?

    var body: some View {
        if let lectureId, let lectureName {
            LectureAttachmentSheet(attachment: nil, lectureId: lectureId, lectureName: lectureName, identity: identity, explicitPage: explicitPage, originalSlideNumber: originalSlideNumber, visibleSlideNumbers: visibleSlideNumbers, studentVersion: studentVersion)
        } else if let unit = attachmentUnit {
            if let attachment = unit.attachment, unit.videoSource == nil || explicitPage != nil || originalSlideNumber != nil {
                LectureAttachmentSheet(attachment: attachment, identity: identity + "/attachment/\(attachment.id)", explicitPage: explicitPage, originalSlideNumber: originalSlideNumber, visibleSlideNumbers: visibleSlideNumbers, studentVersion: studentVersion)
            } else {
                VStack(spacing: 12) {
                    if let attachment = unit.attachment {
                        NavigationLink {
                            LectureAttachmentSheet(attachment: attachment, identity: identity + "/attachment/\(attachment.id)", explicitPage: explicitPage, originalSlideNumber: originalSlideNumber, visibleSlideNumbers: visibleSlideNumbers, studentVersion: studentVersion)
                        } label: {
                            Label(attachment.name ?? "Slides", systemImage: "doc.richtext")
                        }
                        .buttonStyle(ArtemisButton())
                        .padding(.horizontal)
                    }
                    if let source = unit.videoSource, let url = URL(string: source), LectureMediaSource.classify(url) != .invalid {
                        VideoUnitSheetContent(unit: unit, videoSource: url, identity: identity)
                    } else {
                        ContentUnavailableView("Media is unavailable", systemImage: "video.slash", description: Text("The lecture has no valid video link. Try opening its slides."))
                    }
                }
            }
        } else {
            ContentUnavailableView("Attachment is unavailable", systemImage: "doc.questionmark")
        }
    }
}
