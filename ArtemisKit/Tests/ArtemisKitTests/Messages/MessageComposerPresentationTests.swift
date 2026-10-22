import SharedModels
import SwiftUI
import UIKit
import XCTest
@testable import Messages

@MainActor
final class MessageComposerPresentationTests: XCTestCase {
    func testFullscreenControlRendersBesideUnfocusedEditorAndExpandedLayoutGainsSpace() async throws {
        let model = try makeComposer()
        let content = VStack { Spacer(); SendMessageView(viewModel: model) }
        let (controller, window) = await host(content)
        defer { window.isHidden = true; window.rootViewController = nil }
        XCTAssertFalse(model.keyboardVisible)
        XCTAssertFalse(model.formattingExpanded)
        let editor = try XCTUnwrap(findEditor(in: controller.view))
        let editorFrame = editor.convert(editor.bounds, to: controller.view)
        let controls = CGRect(x: editorFrame.maxX, y: editorFrame.minY,
                              width: controller.view.bounds.width - editorFrame.maxX, height: 44)
        let image = attachSnapshot(controller.view, name: "composer-unfocused-resize-control")
        XCTAssertTrue(containsBlueControl(in: controls, image: image), "The resize icon must render beside the field while keyboard and More are closed")
        let collapsedHeight = editor.bounds.height
        model.editorExpanded = true
        controller.rootView = AnyView(content)
        controller.view.layoutIfNeeded()
        _ = controller.sizeThatFits(in: window.bounds.size)
        controller.view.layoutIfNeeded()
        let expandedEditor = try XCTUnwrap(findEditor(in: controller.view))
        XCTAssertGreaterThanOrEqual(expandedEditor.bounds.height - collapsedHeight, 100)
        attachSnapshot(controller.view, name: "composer-expanded-without-keyboard")
    }

    func testGroupedToolbarFitsNarrowPortraitAndCompactLandscape() async throws {
        let model = try makeComposer()
        let toolbar = SendMessageKeyboardToolbar(
            sendButton: Text("Send"), viewModel: model,
            uploadFileViewModel: .init(courseId: model.course.id, conversationId: model.conversation.id),
            uploadImageViewModel: .init(courseId: model.course.id, conversationId: model.conversation.id))
        let (controller, window) = await host(toolbar.environment(\.verticalSizeClass, .regular), size: CGSize(width: 320, height: 200))
        defer { window.isHidden = true; window.rootViewController = nil }
        controller.additionalSafeAreaInsets = UIEdgeInsets(top: 62, left: 0, bottom: 34, right: 0)
        // Measure the toolbar itself; host safe-area insets vary across simulator runtimes.
        controller.safeAreaRegions = []
        controller.view.layoutIfNeeded()
        XCTAssertFalse(model.formattingExpanded)
        XCTAssertLessThanOrEqual(controller.sizeThatFits(in: CGSize(width: 320, height: 200)).height, 44)
        attachSnapshot(controller.view, name: "composer-grouped-toolbar")
        model.formattingExpanded = true
        controller.rootView = AnyView(toolbar.environment(\.verticalSizeClass, .regular))
        XCTAssertGreaterThanOrEqual(controller.sizeThatFits(in: CGSize(width: 320, height: 200)).height, 88)
        controller.rootView = AnyView(toolbar.environment(\.verticalSizeClass, .compact))
        XCTAssertLessThanOrEqual(controller.sizeThatFits(in: CGSize(width: 844, height: 200)).height, 44)
        attachSnapshot(controller.view, name: "composer-expanded-toolbar")
    }

    func testComposerRendersCodeQuotesAndRestoredAttachmentNames() async throws {
        let model = try makeComposer()
        model.performOnAppear()
        model.text = "`inline`\n\n> A **quote**\n\n```swift\nx\na longer line\n```\n\n[Report.pdf](/api/files/report.pdf) ![Diagram](/api/files/image.png)"
        model.editorExpanded = true
        let (controller, window) = await host(VStack { Spacer(); SendMessageView(viewModel: model) })
        defer { window.isHidden = true; window.rootViewController = nil }
        let nativeEditor = try XCTUnwrap(findEditor(in: controller.view))
        XCTAssertEqual(nativeEditor.attributedText.string, model.editor.content.string)
        XCTAssertEqual(MessageEditorCodec.encode(MessageEditorDocument.spans(nativeEditor.attributedText)), model.text)
        XCTAssertEqual(model.editor.attachments.map(\.name), ["Report.pdf", "Diagram"])
        XCTAssertGreaterThanOrEqual(nativeEditor.bounds.height, 200)
        attachSnapshot(controller.view, name: "composer-code-quotes-attachments")
        controller.overrideUserInterfaceStyle = .dark
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()
        attachSnapshot(controller.view, name: "composer-dark-code-quotes-attachments")
    }

    private func makeComposer() throws -> SendMessageViewModel {
        let id = Int.random(in: 7_000_001...8_000_000)
        return SendMessageViewModel(course: CourseForOverviewDTO(course: Course(id: id, courseInformationSharingConfiguration: .communicationAndMessaging)),
                                    conversation: Conversation(conversation: Channel(id: Int64(id)))!, configuration: .message,
                                    delegate: SendMessageViewModelDelegate(presentError: { _ in }, sendMessage: { _ in }),
                                    messagesRepository: try MessagesRepository())
    }

    private func host(_ view: some View, size: CGSize = CGSize(width: 390, height: 844)) async -> (UIHostingController<AnyView>, UIWindow) {
        let appeared = expectation(description: "Composer presentation appeared")
        appeared.assertForOverFulfill = false
        let controller = UIHostingController(rootView: AnyView(view.onAppear { appeared.fulfill() }))
        let window = UIWindow(frame: CGRect(origin: .zero, size: size))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        await fulfillment(of: [appeared], timeout: 2)
        controller.view.layoutIfNeeded()
        return (controller, window)
    }

    private func findEditor(in view: UIView) -> MessageComposerTextView? {
        if let editor = view as? MessageComposerTextView { return editor }
        return view.subviews.lazy.compactMap { self.findEditor(in: $0) }.first
    }

    private func containsBlueControl(in rect: CGRect, image: UIImage) -> Bool {
        guard let cgImage = image.cgImage, let data = cgImage.dataProvider?.data,
              let bytes = CFDataGetBytePtr(data) else { return false }
        let scale = image.scale
        let region = rect.applying(CGAffineTransform(scaleX: scale, y: scale)).intersection(CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
        guard !region.isNull else { return false }
        // UIKit renderer images use BGRA storage. Look for the blue accent in the resize control.
        for y in Int(region.minY)..<Int(region.maxY) {
            for x in Int(region.minX)..<Int(region.maxX) {
                let offset = y * cgImage.bytesPerRow + x * (cgImage.bitsPerPixel / 8)
                if Int(bytes[offset]) > Int(bytes[offset + 2]) + 30, Int(bytes[offset]) > Int(bytes[offset + 1]) + 10 { return true }
            }
        }
        return false
    }

    @discardableResult
    private func attachSnapshot(_ view: UIView, name: String) -> UIImage {
        let image = UIGraphicsImageRenderer(bounds: view.bounds).image { view.layer.render(in: $0.cgContext) }
        let attachment = XCTAttachment(image: image)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("artemis-composer-snapshots")
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? image.pngData()?.write(to: directory.appendingPathComponent(name + ".png"))
        return image
    }
}
