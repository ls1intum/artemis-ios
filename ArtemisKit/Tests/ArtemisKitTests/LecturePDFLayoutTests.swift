import PDFKit
import SwiftUI
import UIKit
import XCTest
@testable import CourseView

@MainActor
final class LecturePDFLayoutTests: XCTestCase {
    func testActualPDFViewKeepsReadingPageAcrossUnmountReopenAndRotation() async throws {
        let url = try makePDF()
        defer { try? FileManager.default.removeItem(at: url) }
        let progress = LectureMediaProgress(account: "pdf-layout", server: URL(string: "https://example.org")!, identity: UUID().uuidString)
        let (host, window) = mount(LecturePDFReader(url: url, explicitPage: nil, progress: progress))
        defer { window.isHidden = true; window.rootViewController = nil }
        let first = try await pdf(in: host)
        first.go(to: try XCTUnwrap(first.document?.page(at: 2)))
        for _ in 0..<100 where progress.pageIndex(explicitPage: nil, pageCount: 8) != 2 { try await Task.sleep(for: .milliseconds(10)) }
        XCTAssertEqual(progress.pageIndex(explicitPage: nil, pageCount: 8), 2)
        host.rootView = AnyView(EmptyView())
        host.view.layoutIfNeeded()
        for _ in 0..<200 where findPDF(in: host.view) != nil {
            host.view.setNeedsLayout(); host.view.layoutIfNeeded()
            try await Task.sleep(for: .milliseconds(10))
        }
        XCTAssertNil(findPDF(in: host.view), "The previous reader must be unmounted before reopening")
        host.rootView = AnyView(LecturePDFReader(url: url, explicitPage: nil, progress: progress))
        let reopened = try await pdf(in: host)
        XCTAssertEqual(index(reopened), 2)
        window.frame = CGRect(x: 0, y: 0, width: 844, height: 390)
        host.view.frame = window.bounds
        host.view.setNeedsLayout(); host.view.layoutIfNeeded()
        reopened.setNeedsLayout(); reopened.layoutIfNeeded()
        let rotated = try await pdf(in: host)
        XCTAssertEqual(index(rotated), 2)
        XCTAssertGreaterThan(rotated.bounds.width, rotated.bounds.height)
        XCTAssertEqual(progress.pageIndex(explicitPage: nil, pageCount: 8), 2)
    }

    func testExplicitPageIsAppliedToNativePDFViewAfterLayout() async throws {
        let url = try makePDF()
        defer { try? FileManager.default.removeItem(at: url) }
        let progress = LectureMediaProgress(account: "pdf-target", server: URL(string: "https://example.org")!, identity: UUID().uuidString)
        progress.save(page: 7)
        let (host, window) = mount(LecturePDFReader(url: url, explicitPage: 3, progress: progress))
        defer { window.isHidden = true; window.rootViewController = nil }
        let view = try await pdf(in: host)
        XCTAssertEqual(index(view), 2)
        XCTAssertEqual(progress.pageIndex(explicitPage: nil, pageCount: 8), 2)
    }

    func testNativePDFDoesNotAcceptInputUntilInitialPlacementIsVerified() async throws {
        let url = try makePDF()
        defer { try? FileManager.default.removeItem(at: url) }
        let progress = LectureMediaProgress(account: "pdf-ready", server: URL(string: "https://example.org")!, identity: UUID().uuidString)
        let reader = LecturePDFReader(url: url, explicitPage: 3, progress: progress)
        let (host, window) = mount(reader.frame(width: 390, height: 0))
        defer { window.isHidden = true; window.rootViewController = nil }
        for _ in 0..<200 where findPDF(in: host.view)?.document?.pageCount != 8 {
            host.view.setNeedsLayout(); host.view.layoutIfNeeded()
            try await Task.sleep(for: .milliseconds(10))
        }
        let initial = try XCTUnwrap(findPDF(in: host.view))
        XCTAssertEqual(initial.bounds.height, 0, accuracy: 0.5)
        XCTAssertFalse(initial.isUserInteractionEnabled, "Gestures cannot be accepted while initial positioning would discard them")
        host.rootView = AnyView(reader.frame(width: 390, height: 844))
        let ready = try await pdf(in: host)
        XCTAssertEqual(index(ready), 2)
    }

    private func index(_ view: PDFView) -> Int? { view.currentPage.flatMap { view.document?.index(for: $0) } }
    private func mount(_ reader: some View) -> (UIHostingController<AnyView>, UIWindow) {
        let host = UIHostingController(rootView: AnyView(reader))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = host; window.makeKeyAndVisible()
        host.view.frame = window.bounds; host.view.layoutIfNeeded()
        return (host, window)
    }
    private func pdf(in host: UIHostingController<AnyView>) async throws -> PDFView {
        for _ in 0..<200 {
            host.view.setNeedsLayout(); host.view.layoutIfNeeded()
            if let view = findPDF(in: host.view), view.document?.pageCount == 8, view.bounds.width > 0, view.bounds.height > 0, view.isUserInteractionEnabled { return view }
            try await Task.sleep(for: .milliseconds(10))
        }
        XCTFail("PDF must finish layout and enable input before navigation")
        throw NSError(domain: "LecturePDFLayoutTests", code: 1)
    }
    private func findPDF(in view: UIView) -> PDFView? {
        if let pdf = view as? PDFView { return pdf }
        return view.subviews.lazy.compactMap { self.findPDF(in: $0) }.first
    }
    private func makePDF() throws -> URL {
        let document = PDFDocument()
        for index in 0..<8 {
            let image = UIGraphicsImageRenderer(size: CGSize(width: 612, height: 792)).image { context in
                UIColor.white.setFill(); context.fill(CGRect(x: 0, y: 0, width: 612, height: 792))
                ("Scanned page \(index + 1)" as NSString).draw(at: CGPoint(x: 40, y: 40), withAttributes: [.font: UIFont.systemFont(ofSize: 30), .foregroundColor: UIColor.black])
            }
            document.insert(try XCTUnwrap(PDFPage(image: image)), at: index)
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("pdf")
        try XCTUnwrap(document.dataRepresentation()).write(to: url)
        return url
    }
}
