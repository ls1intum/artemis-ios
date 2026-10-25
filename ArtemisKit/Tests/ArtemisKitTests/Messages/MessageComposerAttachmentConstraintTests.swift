import SharedModels
import SwiftUI
import UIKit
import XCTest
@testable import Messages

@MainActor
final class MessageComposerAttachmentConstraintTests: XCTestCase {
    func testAttachmentsYieldSpaceToEditorAndToolbarInAShortWindow() async throws {
        for source in ["[Report.pdf](/api/files/report.pdf)", "![Diagram](/api/files/image.png)"] {
            for sizeClass in [UserInterfaceSizeClass.regular, .compact] {
                let model = try makeComposer()
                model.performOnAppear()
                model.text = source
                XCTAssertEqual(model.editor.attachments.count, 1)
                let previousKeyWindow = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
                    .flatMap(\.windows).first(where: \.isKeyWindow)
                let content = VStack(spacing: 0) { Spacer(minLength: 0); SendMessageView(viewModel: model) }
                    .environment(\.verticalSizeClass, sizeClass)
                let (controller, window) = await host(content)
                defer {
                    window.isHidden = true
                    window.rootViewController = nil
                    previousKeyWindow?.makeKeyAndVisible()
                }
                let editor = try XCTUnwrap(findEditor(in: controller.view))
                let frame = editor.convert(editor.bounds, to: controller.view)
                let context = "\(source), \(sizeClass), editor \(frame), host \(controller.view.bounds)"
                XCTAssertGreaterThanOrEqual(frame.minY, -0.5, "Attachments must yield space above the keyboard: \(context)")
                XCTAssertGreaterThanOrEqual(frame.height, 43.5, "Keep one line of the message visible: \(context)")
                XCTAssertLessThanOrEqual(frame.maxY + 44, controller.view.bounds.maxY + 0.5,
                                         "Keep the toolbar inside the keyboard-constrained height: \(context)")
            }
        }
    }

    private func makeComposer() throws -> SendMessageViewModel {
        var channel = Channel(id: 2)
        channel.name = "general"
        return SendMessageViewModel(course: CourseForOverviewDTO(course: Course(id: 1, courseInformationSharingConfiguration: .communicationAndMessaging)),
                                    conversation: Conversation(conversation: channel)!, configuration: .forwardMessage,
                                    delegate: SendMessageViewModelDelegate(presentError: { _ in }, sendMessage: { _ in }),
                                    messagesRepository: try MessagesRepository(inMemory: true), messagesService: MessagesServiceStub())
    }

    private func host(_ view: some View) async -> (UIHostingController<AnyView>, UIWindow) {
        let appeared = expectation(description: "Attachment composer appeared")
        appeared.assertForOverFulfill = false
        let controller = UIHostingController(rootView: AnyView(view.onAppear { appeared.fulfill() }))
        controller.safeAreaRegions = []
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 170))
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
}
