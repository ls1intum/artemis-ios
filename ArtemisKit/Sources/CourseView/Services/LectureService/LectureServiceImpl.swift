//
//  File.swift
//  
//
//  Created by Sven Andabaka on 30.04.23.
//

import Foundation
import UserStore
import Common
import SharedModels
import APIClient

class LectureServiceImpl: LectureService {

    let client = APIClient()

    struct GetVisibleLectureSlidesRequest: APIRequest {
        typealias Response = [LectureMediaDetails]
        let courseId: Int
        var method: HTTPMethod { .get }
        var resourceName: String { "api/lecture/courses/\(courseId)/lectures-with-slides" }
    }

    func getLecturesWithSlides(courseId: Int) async -> DataState<[LectureMediaDetails]> {
        let result = await client.sendRequest(GetVisibleLectureSlidesRequest(courseId: courseId))
        switch result {
        case .success((let response, _)): return .done(response: response)
        case .failure(let error): return .failure(error: UserFacingError(error: error))
        }
    }

    struct GetLectureDetailsRequest: APIRequest {
        typealias Response = LectureMediaDetails

        let lectureId: Int

        var method: HTTPMethod {
            return .get
        }

        var resourceName: String {
            return "api/lecture/lectures/\(lectureId)/details"
        }
    }

    func getLectureDetails(lectureId: Int) async -> DataState<LectureMediaDetails> {
        let result = await client.sendRequest(GetLectureDetailsRequest(lectureId: lectureId))

        switch result {
        case .success((let response, _)):
            return .done(response: response)
        case .failure(let error):
            return .failure(error: UserFacingError(error: error))
        }
    }

    struct UpdateLectureUnitCompletionRequest: APIRequest {
        typealias Response = RawResponse

        let lectureId: Int
        let lectureUnitId: Int64
        let completed: Bool

        var method: HTTPMethod {
            return .post
        }

        var resourceName: String {
            return "api/lecture/lectures/\(lectureId)/lecture-units/\(lectureUnitId)/completion?completed=\(completed)"
        }
    }

    func updateLectureUnitCompletion(lectureId: Int, lectureUnitId: Int64, completed: Bool) async -> NetworkResponse {
        let result = await client.sendRequest(UpdateLectureUnitCompletionRequest(lectureId: lectureId,
                                                                                 lectureUnitId: lectureUnitId,
                                                                                 completed: completed))

        switch result {
        case .success:
            return .success
        case .failure(let error):
            return .failure(error: UserFacingError(error: error))
        }
    }

    func getAttachmentFile(link: String, name: String? = nil) async -> DataState<LectureAttachmentFile> {
        guard let snapshot = LectureMediaSession.capture() else {
            return .failure(error: UserFacingError(title: LectureMediaError.sessionChanged.localizedDescription))
        }
        guard let url = URL(string: link, relativeTo: snapshot.origin)?.absoluteURL,
              LectureMediaOrigin.matches(snapshot.origin, url) else {
            return .failure(error: UserFacingError(title: LectureMediaError.invalidURL.localizedDescription))
        }
        do {
            let loader = LectureMediaDownloader(policy: snapshot.policy)
            var studentVersion = url.pathComponents.contains("student")
            let data: Data
            let response: HTTPURLResponse
            do {
                (data, response) = try await loader.data(from: url)
            } catch LectureMediaError.response(403) where !studentVersion {
                studentVersion = true
                let studentURL = url.deletingLastPathComponent().appending(path: "student").appending(path: url.lastPathComponent)
                (data, response) = try await loader.data(from: studentURL)
            }
            try Task.checkCancellation()
            guard snapshot.isCurrent else { throw LectureMediaError.sessionChanged }
            let isPDF = response.mimeType?.lowercased() == "application/pdf" || url.pathExtension.lowercased() == "pdf"
            let fileExtension = isPDF ? "pdf" : url.pathExtension
            let directory = FileManager.default.temporaryDirectory.appendingPathComponent("lecture-media-" + UUID().uuidString)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let safeName = (name.map { URL(fileURLWithPath: $0).lastPathComponent } ?? "Attachment")
            let previewURL = directory.appendingPathComponent(safeName).appendingPathExtension(fileExtension)
            try data.write(to: previewURL, options: .atomic)
            return .done(response: LectureAttachmentFile(url: previewURL, studentVersion: studentVersion))
        } catch {
            return .failure(error: UserFacingError(title: error is CancellationError ? "Loading was cancelled. Try again." : error.localizedDescription))
        }
    }

    struct GetLectureChannelRequest: APIRequest {
        typealias Response = Channel

        let courseId: Int
        let lectureId: Int

        var method: HTTPMethod {
            .get
        }

        var resourceName: String {
            "api/communication/courses/\(courseId)/lectures/\(lectureId)/channel"
        }
    }

    func getAssociatedChannel(for lectureId: Int, in courseId: Int) async -> DataState<Channel> {
        let result = await client.sendRequest(GetLectureChannelRequest(courseId: courseId, lectureId: lectureId))

        switch result {
        case let .success((response, _)):
            return .done(response: response)
        case let .failure(error):
            return .failure(error: UserFacingError(error: error))
        }
    }
}
