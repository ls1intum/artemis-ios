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

    struct GetLectureDetailsRequest: APIRequest {
        typealias Response = Lecture

        let lectureId: Int

        var method: HTTPMethod {
            return .get
        }

        var resourceName: String {
            return "api/lecture/lectures/\(lectureId)/details"
        }
    }

    func getLectureDetails(lectureId: Int) async -> DataState<Lecture> {
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

    func getAttachmentFile(link: String, name: String? = nil) async -> DataState<URL> {
        guard let url = URL(string: link, relativeTo: UserSessionFactory.shared.institution?.baseURL) else {
            return .failure(error: UserFacingError(title: "Wrong URL"))
        }
        do {
            var (data, response) = try await URLSession.shared.data(from: url)

            // Accessing lecture attachment as student needs a different URL sometimes
            if (response as? HTTPURLResponse)?.statusCode == 403 {
                let lastPathComponent = url.lastPathComponent
                let newUrl = url
                    .deletingLastPathComponent()
                    .appending(path: "student")
                    .appending(path: lastPathComponent)

                (data, _) = try await URLSession.shared.data(from: newUrl)
            }

            let fileExtension = url.pathExtension
            let suggestedFilename = name?.appending("." + fileExtension) ?? url.lastPathComponent
            let previewURL = FileManager.default.temporaryDirectory.appendingPathComponent(suggestedFilename)
            try data.write(to: previewURL, options: .atomic)   // atomic option overwrites it if needed
            return .done(response: previewURL)
        } catch {
            return .failure(error: UserFacingError(title: error.localizedDescription))
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
