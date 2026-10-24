import SharedModels
import SwiftUI
import UIKit
import XCTest
@testable import Messages

@MainActor
final class MessageComposerPresentationTests: XCTestCase {
    func testEditorUsesFullComposerWidthWithoutAResizeColumn() async throws {
        let model = try makeComposer()
        let content = VStack { Spacer(); SendMessageView(viewModel: model) }
        let (controller, window) = await host(content)
        defer { window.isHidden = true; window.rootViewController = nil }
        XCTAssertFalse(model.formattingExpanded)
        let editor = try XCTUnwrap(findEditor(in: controller.view))
        XCTAssertFalse(editor.isFirstResponder)
        let editorFrame = editor.convert(editor.bounds, to: controller.view)
        XCTAssertGreaterThanOrEqual(editorFrame.width, 340, "Actions belong below the text so the editor can use the full width")
        XCTAssertLessThanOrEqual(editorFrame.height, 60)
        attachSnapshot(controller.view, name: "composer-empty")
    }

    func testFormattingReplacesTheSameToolbarRowAtEveryWidth() async throws {
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
        attachSnapshot(controller.view, name: "composer-default-toolbar")
        model.formattingExpanded = true
        controller.rootView = AnyView(toolbar.environment(\.verticalSizeClass, .regular))
        XCTAssertLessThanOrEqual(controller.sizeThatFits(in: CGSize(width: 320, height: 200)).height, 44)
        controller.rootView = AnyView(toolbar.environment(\.verticalSizeClass, .compact))
        XCTAssertLessThanOrEqual(controller.sizeThatFits(in: CGSize(width: 844, height: 200)).height, 44)
        attachSnapshot(controller.view, name: "composer-formatting-toolbar")
    }

    func testComposerRendersCodeQuotesAndRestoredAttachmentNames() async throws {
        let model = try makeComposer()
        model.performOnAppear()
        model.text = "`inline`\n\n> A **quote**\n\n```swift\nx\na longer line\n```\n\n[Report.pdf](/api/files/report.pdf) ![Diagram](/api/files/image.png)"
        let (controller, window) = await host(VStack { Spacer(); SendMessageView(viewModel: model) })
        defer { window.isHidden = true; window.rootViewController = nil }
        let nativeEditor = try XCTUnwrap(findEditor(in: controller.view))
        XCTAssertEqual(nativeEditor.attributedText.string, model.editor.content.string)
        XCTAssertEqual(MessageEditorCodec.encode(MessageEditorDocument.spans(nativeEditor.attributedText)), model.text)
        XCTAssertEqual(model.editor.attachments.map(\.name), ["Report.pdf", "Diagram"])
        XCTAssertLessThanOrEqual(nativeEditor.bounds.height, 160)
        attachSnapshot(controller.view, name: "composer-code-quotes-attachments")
        controller.overrideUserInterfaceStyle = .dark
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()
        attachSnapshot(controller.view, name: "composer-dark-code-quotes-attachments")
    }

    func testLongDraftKeepsToolbarInTheAvailableHeight() async throws {
        let model = try makeComposer()
        model.performOnAppear()
        model.text = String(repeating: "A longer message line\n", count: 30)
        model.formattingExpanded = true
        let content = VStack(spacing: 0) { Spacer(minLength: 0); SendMessageView(viewModel: model) }
            .environment(\.verticalSizeClass, .compact)
        let (controller, window) = await host(content, size: CGSize(width: 320, height: 200))
        defer { window.isHidden = true; window.rootViewController = nil }
        controller.safeAreaRegions = []
        controller.view.layoutIfNeeded()
        let editor = try XCTUnwrap(findEditor(in: controller.view))
        let frame = editor.convert(editor.bounds, to: controller.view)
        XCTAssertGreaterThanOrEqual(frame.minY, 0)
        XCTAssertLessThanOrEqual(editor.bounds.height, 80)
        XCTAssertLessThanOrEqual(frame.maxY + 44, controller.view.bounds.maxY)
        XCTAssertTrue(editor.isScrollEnabled)
        attachSnapshot(controller.view, name: "composer-narrow-short-height")
    }

    func testWideAndLargeTextComposerKeepsOneToolbarRow() async throws {
        let model = try makeComposer()
        model.performOnAppear()
        model.text = "> A **quoted** message\n> Another line\n\nA reply with `code`."
        model.formattingExpanded = true
        let content = VStack { Spacer(); SendMessageView(viewModel: model) }
            .environment(\.dynamicTypeSize, .accessibility3)
        let (controller, window) = await host(content, size: CGSize(width: 768, height: 700))
        defer { window.isHidden = true; window.rootViewController = nil }
        let editor = try XCTUnwrap(findEditor(in: controller.view))
        XCTAssertGreaterThanOrEqual(editor.bounds.width, 700)
        XCTAssertLessThanOrEqual(editor.bounds.height, 160)
        attachSnapshot(controller.view, name: "composer-wide-large-text")
    }

    func testCompletionsLeaveTheEditorAndToolbarVisibleInAShortWindow() async throws {
        for query in ["@alex", "#general"] {
            for sizeClass in [UserInterfaceSizeClass.regular, .compact] {
                let model = try makeComposer()
                model.performOnAppear()
                model.text = "A longer message\nAnother line\n\(query)"
                model.editor.selection = NSRange(location: model.editor.content.length, length: 0)
                XCTAssertNotNil(model.conditionalPresentation)
                let content = VStack(spacing: 0) { Spacer(minLength: 0); SendMessageView(viewModel: model) }
                    .environment(\.verticalSizeClass, sizeClass)
                let (controller, window) = await host(content, size: CGSize(width: 390, height: 170))
                defer { window.isHidden = true; window.rootViewController = nil }
                controller.safeAreaRegions = []
                controller.view.layoutIfNeeded()
                let editor = try XCTUnwrap(findEditor(in: controller.view))
                let frame = editor.convert(editor.bounds, to: controller.view)
                XCTAssertGreaterThanOrEqual(frame.minY, 0, "Completion suggestions must yield space to the composer")
                XCTAssertGreaterThanOrEqual(frame.height, 44, "Keep at least one line of the message visible")
                XCTAssertLessThanOrEqual(frame.maxY + 44, controller.view.bounds.maxY, "Keep the toolbar above the keyboard")
                attachSnapshot(controller.view, name: "composer-completion-\(query.first!)-\(sizeClass)")
            }
        }
    }

    func testExpandedEditorAddsSpaceButKeepsTheToolbarInsideAShortWindow() async throws {
        let document = MessageEditorDocument()
        document.load("A draft with **formatting**")
        for height in [600.0, 170.0] {
            let content = VStack(spacing: 0) {
                Spacer(minLength: 0)
                MessageRichTextEditor(document: document, placeholder: "Message", isFocused: .constant(false), extraHeight: 240)
                Color.clear.frame(height: 44)
            }
            let (controller, window) = await host(content, size: CGSize(width: 390, height: height))
            defer { window.isHidden = true; window.rootViewController = nil }
            controller.safeAreaRegions = []
            controller.view.layoutIfNeeded()
            let editor = try XCTUnwrap(findEditor(in: controller.view))
            let frame = editor.convert(editor.bounds, to: controller.view)
            XCTAssertGreaterThanOrEqual(frame.height, height > 200 ? 280 : 44)
            XCTAssertGreaterThanOrEqual(frame.minY, 0)
            XCTAssertLessThanOrEqual(frame.maxY + 44, height)
            XCTAssertTrue(editor.isScrollEnabled)
            XCTAssertEqual(document.markdown, "A draft with **formatting**")
        }
    }

    func testComposerClaimsItsContentHeightBeforeTheConversationScrollView() async throws {
        let model = try makeComposer()
        model.performOnAppear()
        model.text = String(repeating: "A longer message line\n", count: 30)
        let content = NavigationStack {
            VStack(spacing: 0) {
                Text("Conversation preview")
                VStack(spacing: 0) {
                    ScrollView { Text(String(repeating: "An earlier message\n", count: 40)) }
                    SendMessageView(viewModel: model)
                }
            }
            .navigationTitle("general")
            .navigationBarTitleDisplayMode(.inline)
        }
        .environment(\.verticalSizeClass, .regular)
        let (controller, window) = await host(content, size: CGSize(width: 390, height: 450))
        defer { window.isHidden = true; window.rootViewController = nil }
        controller.safeAreaRegions = []
        controller.view.layoutIfNeeded()
        let editor = try XCTUnwrap(findEditor(in: controller.view))
        XCTAssertGreaterThanOrEqual(editor.bounds.height, 159.5, "The message list should yield space to the composer's bounded content")
    }

    private func makeComposer() throws -> SendMessageViewModel {
        let id = Int.random(in: 7_000_001...8_000_000)
        var channel = Channel(id: Int64(id))
        channel.name = "general"
        return SendMessageViewModel(course: CourseForOverviewDTO(course: Course(id: id, courseInformationSharingConfiguration: .communicationAndMessaging)),
                                    conversation: Conversation(conversation: channel)!, configuration: .message,
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

    @discardableResult
    private func attachSnapshot(_ view: UIView, name: String) -> UIImage {
        // These unhosted test captures verify layout. Inspect materials with Simulator screenshots.
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
