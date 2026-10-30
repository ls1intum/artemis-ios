import Navigation
import SharedModels
import SwiftUI
import UIKit
import XCTest
@testable import Messages

@MainActor
final class ConversationScrollLayoutTests: XCTestCase {
    func testQueuedOwnMessageRemainsVisibleBeforeServerAcknowledgement() async throws {
        let model = try makeConversation()
        let (controller, window, previousKeyWindow) = try await host(model)
        defer { close(window, restoring: previousKeyWindow) }
        let scrollView = try conversationScrollView(in: controller.view)
        try await scrollToBottom(scrollView, controller: controller)
        let previousHeight = scrollView.contentSize.height

        // Use the same persistent queue entry point as the real composer. The
        // injected MessagesServiceStub keeps sending in .loading, so no acknowledgement
        // or websocket event can scroll the accepted message on our behalf.
        let accepted = await SendMessageViewModelDelegate(model).sendMessage("Queued own message awaiting acknowledgement")
        XCTAssertTrue(accepted)
        try await waitForLayout(controller, description: "The pending message is laid out") {
            scrollView.contentSize.height > previousHeight + 20
        }

        XCTAssertEqual(model.offlineMessages.count, 1, "Keep the optimistic row pending while measuring its visibility")
        XCTAssertGreaterThan(scrollView.contentSize.height, previousHeight + 20, "The queued message must actually be laid out")
        XCTAssertLessThanOrEqual(distanceFromBottom(scrollView), 2,
                                 "Sending at the bottom must reveal the pending message immediately, before the server replies")
    }

    func testLoadingHistoryDoesNotReplayAStaleNewMessageScroll() async throws {
        let model = try makeConversation()
        let historyMessages = model.messages.sorted { $0.id < $1.id }
        // Establish history through SwiftUI's scroll target so its state matches the viewport.
        model.shouldScrollToId = historyMessages[historyMessages.count / 2].id.description
        let (controller, window, previousKeyWindow) = try await host(model)
        defer { close(window, restoring: previousKeyWindow) }
        let scrollView = try conversationScrollView(in: controller.view)
        try await waitForLayout(controller, description: "The reader has scrolled into history") {
            self.distanceFromBottom(scrollView) > scrollView.bounds.height
        }
        let previousHeight = scrollView.contentSize.height
        XCTAssertGreaterThan(distanceFromBottom(scrollView), scrollView.bounds.height,
                             "Start reading history far enough from the newest message to detect an unwanted jump")
        XCTAssertNil(model.shouldScrollToId, "Consume the initial history scroll before seeding a stale request")
        let newestMessage = try XCTUnwrap(model.messages.max(by: { $0.id < $1.id }))
        model.shouldScrollToId = newestMessage.id.description

        // A previously requested incoming-message scroll must not be replayed
        // when an earlier page changes the message collection.
        await model.loadEarlierMessages()
        try await waitForLayout(controller, description: "The earlier page is laid out") {
            scrollView.contentSize.height > previousHeight + 20
        }

        let addedHeight = scrollView.contentSize.height - previousHeight
        XCTAssertGreaterThan(addedHeight, 20, "The earlier page must actually be laid out")
        XCTAssertGreaterThan(distanceFromBottom(scrollView), scrollView.bounds.height,
                             "Loading history must not replay a stale scroll to the newest message")
    }

    func testShrinkingTheViewportKeepsTheNewestMessageVisible() async throws {
        let model = try makeConversation()
        let (controller, window, previousKeyWindow) = try await host(model)
        defer { close(window, restoring: previousKeyWindow) }
        let scrollView = try conversationScrollView(in: controller.view)
        try await scrollToBottom(scrollView, controller: controller)
        let previousViewportHeight = scrollView.bounds.height

        // A smaller viewport covers keyboard/composer growth and window resizing
        // without synthesizing UIKit keyboard notifications.
        window.frame.size.height = 420
        window.layoutIfNeeded()
        try await waitForLayout(controller, description: "The conversation viewport has shrunk") {
            scrollView.bounds.height < previousViewportHeight - 100
        }

        XCTAssertLessThan(scrollView.bounds.height, previousViewportHeight - 100)
        XCTAssertLessThanOrEqual(distanceFromBottom(scrollView), 2,
                                 "Reducing the available height at the bottom must keep the newest message on screen")
    }

    private func makeConversation() throws -> ConversationViewModel {
        let model = ConversationViewModel(
            course: MessagesServiceStub.course,
            conversation: MessagesServiceStub.conversation,
            messagesRepository: try MessagesRepository(inMemory: true),
            messagesService: MessagesServiceStub(),
            skipLoadingData: true)
        model.isLoadingMessages = false
        model.messages = Set((0..<30).map { index in
            var message = Message(id: Int64(10_000 + index))
            message.author = index.isMultiple(of: 2) ? MessagesServiceStub.alice : MessagesServiceStub.bob
            message.creationDate = MessagesServiceStub.now.addingTimeInterval(TimeInterval(86_400 + index * 600))
            message.content = "History message \(index)\nA second line makes the conversation taller than its viewport."
            return IdentifiableMessage.message(message)
        })
        return model
    }

    private func host(_ model: ConversationViewModel) async throws
        -> (UIHostingController<AnyView>, UIWindow, UIWindow?) {
        let navigationController = NavigationController()
        navigationController.courseTab = .communication
        let content = ConversationView(viewModel: model)
            .environmentObject(navigationController)
            // Measure final positions without the initial requested scroll animating into place.
            .transaction { transaction in
                transaction.animation = nil
                transaction.disablesAnimations = true
            }
        let controller = UIHostingController(rootView: AnyView(content))
        controller.safeAreaRegions = []
        let window = try makeTestWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 760))
        let previousKeyWindow = window.windowScene?.windows.first(where: \.isKeyWindow)
        window.rootViewController = controller
        window.makeKeyAndVisible()
        try await waitForLayout(controller, description: "The conversation scroll hierarchy is laid out") {
            guard let scrollView = self.conversationScrollViewCandidate(in: controller.view) else { return false }
            return scrollView.contentSize.height > scrollView.bounds.height + 200
        }
        return (controller, window, previousKeyWindow)
    }

    private func conversationScrollView(in view: UIView) throws -> UIScrollView {
        let scrollView = try XCTUnwrap(conversationScrollViewCandidate(in: view))
        XCTAssertGreaterThan(scrollView.contentSize.height, scrollView.bounds.height + 200,
                             "The fixture must require scrolling to reveal the newest message")
        return scrollView
    }

    private func conversationScrollViewCandidate(in view: UIView) -> UIScrollView? {
        descendants(of: view).compactMap { $0 as? UIScrollView }
            .filter { !($0 is UITextView) && $0.bounds.height > 200 }
            .max(by: { $0.bounds.height < $1.bounds.height })
    }

    private func descendants(of view: UIView) -> [UIView] {
        view.subviews.flatMap { [$0] + descendants(of: $0) }
    }

    private func scrollToBottom(_ scrollView: UIScrollView, controller: UIHostingController<AnyView>) async throws {
        scrollView.setContentOffset(CGPoint(x: 0, y: maximumOffset(scrollView)), animated: false)
        try await waitForLayout(controller, description: "The reader has reached the bottom") {
            self.distanceFromBottom(scrollView) <= 2
        }
        XCTAssertLessThanOrEqual(distanceFromBottom(scrollView), 2, "Start the scenario at the bottom")
    }

    private func maximumOffset(_ scrollView: UIScrollView) -> CGFloat {
        max(-scrollView.adjustedContentInset.top,
            scrollView.contentSize.height - scrollView.bounds.height + scrollView.adjustedContentInset.bottom)
    }

    private func distanceFromBottom(_ scrollView: UIScrollView) -> CGFloat {
        abs(maximumOffset(scrollView) - scrollView.contentOffset.y)
    }

    private struct LayoutSample: Equatable {
        let hostBounds: CGRect
        let viewport: CGRect
        let contentSize: CGSize
        let contentOffset: CGPoint
        let contentInset: UIEdgeInsets
    }

    private func waitForLayout(_ controller: UIHostingController<AnyView>, description: String,
                               file: StaticString = #filePath, line: UInt = #line,
                               until mutationIsVisible: () -> Bool) async throws {
        let clock = ContinuousClock()
        let startedAt = clock.now
        let deadline = startedAt.advanced(by: .seconds(3))
        var previousSample: LayoutSample?
        var stableSamples = 0
        var totalSamples = 0
        var peakStableSamples = 0
        var firstVisibleAfter: Duration?
        var lastLayoutChange: (previous: LayoutSample, current: LayoutSample)?
        // Start measuring stability only after the requested change is visible;
        // an unchanged hierarchy before SwiftUI commits is not a settled result.
        while clock.now < deadline {
            totalSamples += 1
            controller.view.setNeedsLayout()
            controller.view.layoutIfNeeded()
            if mutationIsVisible(), let scrollView = conversationScrollViewCandidate(in: controller.view) {
                firstVisibleAfter = firstVisibleAfter ?? startedAt.duration(to: clock.now)
                let sample = LayoutSample(hostBounds: controller.view.bounds, viewport: scrollView.bounds,
                                          contentSize: scrollView.contentSize, contentOffset: scrollView.contentOffset,
                                          contentInset: scrollView.adjustedContentInset)
                if let previousSample, sample != previousSample { lastLayoutChange = (previousSample, sample) }
                stableSamples = sample == previousSample ? stableSamples + 1 : 0
                peakStableSamples = max(peakStableSamples, stableSamples)
                previousSample = sample
                if stableSamples >= 5 { return }
            } else {
                previousSample = nil
                stableSamples = 0
            }
            try await Task.sleep(for: .milliseconds(20))
        }
        XCTFail("Timed out waiting for stable layout: \(description). Iterations: \(totalSamples), max stable: \(peakStableSamples), " +
                "first visible after: \(String(describing: firstVisibleAfter)). Last change: \(String(describing: lastLayoutChange)). " +
                "Last geometry: \(String(describing: previousSample))",
                file: file, line: line)
    }

    private func close(_ window: UIWindow, restoring previousKeyWindow: UIWindow?) {
        window.isHidden = true
        window.rootViewController = nil
        previousKeyWindow?.makeKeyAndVisible()
    }
}
