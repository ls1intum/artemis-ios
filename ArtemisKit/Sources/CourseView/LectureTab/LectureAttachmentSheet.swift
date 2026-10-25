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
    var refreshSlide: (() async -> DataState<LectureSlideAccess>)?

    @ObservedObject private var session = UserSessionFactory.shared
    @State private var snapshot = LectureMediaSession.capture()
    @State private var previewURL: DataState<LectureAttachmentFile> = .loading
    @State private var resolvedPage: Int?
    @State private var loadedIdentity = "attachment"
    @State private var generation = LectureMediaLoadGeneration()

    var body: some View {
        DataStateView(data: $previewURL, retryHandler: { await loadAttachment() }) { file in
            let url = file.url
            if url.pathExtension.lowercased() == "pdf" {
                LecturePDFReader(url: url, explicitPage: resolvedPage, progress: snapshot?.progress(identity: loadedIdentity + (file.studentVersion ? "/student" : "/original")), requiresExactPage: originalSlideNumber != nil || refreshSlide != nil)
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
        var selectedAttachment = attachment
        var selectedStudentVersion = studentVersion
        var original = originalSlideNumber
        var visible = visibleSlideNumbers
        if let refreshSlide {
            let refreshed = await refreshSlide()
            guard !Task.isCancelled, generation.accepts(request) else { return }
            guard snapshot.isCurrent else {
                previewURL = .failure(error: UserFacingError(title: LectureMediaError.sessionChanged.localizedDescription))
                return
            }
            switch refreshed {
            case .done(let access):
                // File identity and visible indices come from this same fresh payload.
                selectedAttachment = access.attachment
                selectedStudentVersion = access.studentVersion
                original = access.originalSlideNumber
                visible = access.visibleSlideNumbers
            case .failure(let error): previewURL = .failure(error: error); return
            case .loading:
                previewURL = .failure(error: UserFacingError(title: "Slide information could not be loaded. Try again.")); return
            }
        }
        loadedIdentity = identity + (selectedAttachment.map { "/attachment/\($0.id)" } ?? "")
        var result: DataState<LectureAttachmentFile>
        if let lectureId, let lectureName {
            result = await LectureServiceFactory.shared.getAttachmentFile(link: "/api/core/files/attachments/lectures/\(lectureId)/merge-pdf", name: lectureName)
        } else if let link = selectedStudentVersion ?? selectedAttachment?.link, !link.isEmpty {
            // Preserve absolute links for origin validation in the authenticated loader.
            let normalized = link.hasPrefix("/api/core/files/") || URL(string: link)?.scheme != nil ? link : "/api/core/files/\(link)"
            result = await LectureServiceFactory.shared.getAttachmentFile(link: normalized, name: selectedAttachment?.name)
        } else {
            result = .failure(error: UserFacingError(title: "There is no download link for this attachment."))
        }
        if selectedStudentVersion != nil, case .done(let file) = result {
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
        if let original, case .done(let file) = result {
            guard let page = LectureMediaSlidePage.page(original: original, visibleNumbers: visible ?? [], studentVersion: file.studentVersion) else {
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
    var refreshSlide: (() async -> DataState<LectureSlideAccess>)?

    var body: some View {
        if let lectureId, let lectureName {
            LectureAttachmentSheet(attachment: nil, lectureId: lectureId, lectureName: lectureName, identity: identity, explicitPage: explicitPage, originalSlideNumber: originalSlideNumber, visibleSlideNumbers: visibleSlideNumbers, studentVersion: studentVersion, refreshSlide: refreshSlide)
        } else if let unit = attachmentUnit {
            if let attachment = unit.attachment, unit.videoSource == nil || explicitPage != nil || originalSlideNumber != nil || refreshSlide != nil {
                LectureAttachmentSheet(attachment: attachment, identity: identity, explicitPage: explicitPage, originalSlideNumber: originalSlideNumber, visibleSlideNumbers: visibleSlideNumbers, studentVersion: studentVersion, refreshSlide: refreshSlide)
            } else {
                VStack(spacing: 12) {
                    if let attachment = unit.attachment {
                        NavigationLink {
                            LectureAttachmentSheet(attachment: attachment, identity: identity, explicitPage: explicitPage, originalSlideNumber: originalSlideNumber, visibleSlideNumbers: visibleSlideNumbers, studentVersion: studentVersion, refreshSlide: refreshSlide)
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
