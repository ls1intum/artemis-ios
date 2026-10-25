import Common
import UIKit
import XCTest
@testable import Messages

@MainActor
final class MessageImageUploadTests: XCTestCase {
    func testMissingImageDataEndsLoadingWithAnError() async throws {
        let model = makeModel()
        model.loadImage { nil }
        let loading = try XCTUnwrap(model.uploadTask)
        await loading.value

        XCTAssertNotNil(model.error)
        XCTAssertFalse(model.isUploading)
        XCTAssertNil(model.filePath)
        XCTAssertNil(model.image)
    }

    func testImageTransferFailureEndsLoadingWithAnError() async throws {
        let model = makeModel()
        model.loadImage { throw NSError(domain: "ImageTransferTests", code: 1) }
        let loading = try XCTUnwrap(model.uploadTask)
        await loading.value

        XCTAssertNotNil(model.error)
        XCTAssertFalse(model.isUploading)
        XCTAssertNil(model.filePath)
        XCTAssertNil(model.image)
    }

    func testInvalidImageDataEndsLoadingWithAnError() async throws {
        let model = makeModel()
        model.loadImage { Data("Invalid image data".utf8) }
        let loading = try XCTUnwrap(model.uploadTask)
        await loading.value

        XCTAssertNotNil(model.error)
        XCTAssertFalse(model.isUploading)
        XCTAssertNil(model.filePath)
        XCTAssertNil(model.image)
    }

    func testCancellingImageLoadingDiscardsALateSuccessfulTransfer() async throws {
        let model = makeModel()
        let data = try imageData(color: .red)
        let started = expectation(description: "Image transfer started")
        var finish: CheckedContinuation<Data?, Error>?
        model.loadImage {
            try await withCheckedThrowingContinuation { continuation in
                finish = continuation
                started.fulfill()
            }
        }
        let loading = try XCTUnwrap(model.uploadTask)
        await fulfillment(of: [started], timeout: 2)
        XCTAssertEqual(model.uploadState, .compressing)

        model.cancel()
        XCTAssertTrue(loading.isCancelled, "Cancellation must reach the image transfer task")
        XCTAssertEqual(model.uploadState, .idle)
        finish?.resume(returning: data)
        await loading.value
        await model.uploadTask?.value

        XCTAssertEqual(model.uploadState, .idle, "A loader that ignores cancellation must not restart an upload")
        XCTAssertNil(model.image)
        XCTAssertNil(model.filePath)
        XCTAssertNil(model.uploadTask)
    }

    func testCancellingAQueuedImageLoadPreventsTheTransferFromStarting() async throws {
        let model = makeModel()
        let data = try imageData(color: .red)
        var didLoadData = false
        model.loadImage {
            didLoadData = true
            return data
        }
        let loading = try XCTUnwrap(model.uploadTask)

        model.cancel()
        await loading.value
        await model.uploadTask?.value

        XCTAssertFalse(didLoadData)
        XCTAssertEqual(model.uploadState, .idle)
        XCTAssertNil(model.image)
        XCTAssertNil(model.filePath)
    }

    func testCancelledImageTransferDoesNotPublishALateError() async throws {
        let model = makeModel()
        let started = expectation(description: "Image transfer started")
        var finish: CheckedContinuation<Data?, Error>?
        model.loadImage {
            try await withCheckedThrowingContinuation { continuation in
                finish = continuation
                started.fulfill()
            }
        }
        let loading = try XCTUnwrap(model.uploadTask)
        await fulfillment(of: [started], timeout: 2)

        model.cancel()
        finish?.resume(throwing: NSError(domain: "ImageTransferTests", code: 2))
        await loading.value

        XCTAssertEqual(model.uploadState, .idle)
        XCTAssertNil(model.error)
        XCTAssertNil(model.image)
        XCTAssertNil(model.filePath)
    }

    func testNewImageSelectionKeepsItsImageWhenAnOlderTransferCompletes() async throws {
        let model = makeModel()
        let olderData = try imageData(color: .red)
        let newerData = try imageData(color: .blue)
        let started = expectation(description: "Old image transfer started")
        var finish: CheckedContinuation<Data?, Error>?
        model.loadImage {
            try await withCheckedThrowingContinuation { continuation in
                finish = continuation
                started.fulfill()
            }
        }
        let olderLoading = try XCTUnwrap(model.uploadTask)
        await fulfillment(of: [started], timeout: 2)

        model.loadImage { newerData }
        let newerLoading = try XCTUnwrap(model.uploadTask)
        await newerLoading.value
        await model.uploadTask?.value
        XCTAssertEqual(model.image?.pngData(), UIImage(data: newerData)?.pngData())

        finish?.resume(returning: olderData)
        await olderLoading.value
        await model.uploadTask?.value

        XCTAssertEqual(model.image?.pngData(), UIImage(data: newerData)?.pngData(), "An older transfer must not replace the selected image")
        XCTAssertEqual(model.uploadState, .uploading)
    }

    private func makeModel() -> SendMessageUploadImageViewModel {
        SendMessageUploadImageViewModel(courseId: 1, conversationId: 2, messagesService: MessagesServiceStub())
    }

    private func imageData(color: UIColor) throws -> Data {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 2, height: 2)).image { context in
            color.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 2, height: 2))
        }
        return try XCTUnwrap(image.pngData())
    }
}
