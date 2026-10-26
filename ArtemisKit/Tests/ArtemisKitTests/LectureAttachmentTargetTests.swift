import Common
import PDFKit
import SharedModels
import SwiftUI
import UIKit
import UserStore
import XCTest
@testable import CourseView

@MainActor
final class LectureAttachmentTargetTests: XCTestCase {
    func testAsyncAttachmentPublishesTheFileAndExactOriginalPageTogether() async throws {
        try await checkPage(studentVersion: false, pageCount: 8, expectedIndex: 7)
    }

    func testAsyncStudentAttachmentPublishesItsMappedPageTogetherWithTheFile() async throws {
        try await checkPage(studentVersion: true, pageCount: 3, expectedIndex: 2)
    }

    private func checkPage(studentVersion: Bool, pageCount: Int, expectedIndex: Int) async throws {
        let session = UserSessionFactory.shared
        let wasLoggedIn = session.isLoggedIn, oldUsername = session.username, wasExpired = session.tokenExpired
        session.saveUsername(username: "lecture-attachment-test")
        session.setUserLoggedIn(isLoggedIn: true)
        session.setTokenExpired(expired: false)
        defer {
            session.saveUsername(username: oldUsername)
            session.setUserLoggedIn(isLoggedIn: wasLoggedIn)
            session.setTokenExpired(expired: wasExpired)
        }
        XCTAssertNotNil(LectureMediaSession.capture())
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("lecture-media-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("visible.pdf")
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
        try renderer.writePDF(to: url) { context in
            for page in 1...pageCount {
                context.beginPage()
                ("Page \(page)" as NSString).draw(at: CGPoint(x: 40, y: 40), withAttributes: [.font: UIFont.systemFont(ofSize: 30)])
            }
        }
        let attachment = try JSONDecoder().decode(Attachment.self, from: Data(#"{"id":10,"link":"original.pdf"}"#.utf8))
        let reader = LectureAttachmentSheet(attachment: attachment, identity: UUID().uuidString,
                                            originalSlideNumber: 8, visibleSlideNumbers: [1, 3, 8],
                                            studentVersion: studentVersion ? "student.pdf" : nil,
                                            loadFile: { _, _ in
                                                await Task.yield()
                                                return .done(response: LectureAttachmentFile(url: url, studentVersion: false))
                                            })
        let host = UIHostingController(rootView: reader)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 580, height: 640))
        window.rootViewController = host; window.makeKeyAndVisible()
        defer { window.isHidden = true; window.rootViewController = nil }
        var native: PDFView?
        for _ in 0..<200 {
            host.view.setNeedsLayout(); host.view.layoutIfNeeded()
            if let view = pdf(in: host.view), view.document?.pageCount == pageCount, view.isUserInteractionEnabled,
               view.bounds.width > 0, view.bounds.height > 0 { native = view; break }
            try await Task.sleep(for: .milliseconds(10))
        }
        let view = try XCTUnwrap(native)
        let page = try XCTUnwrap(view.currentPage)
        XCTAssertEqual(view.document?.index(for: page), expectedIndex)
    }

    private func pdf(in view: UIView) -> PDFView? {
        if let pdf = view as? PDFView { return pdf }
        return view.subviews.lazy.compactMap { self.pdf(in: $0) }.first
    }
}
