//
//  LectureServiceImpl.swift
//
//
//  Created by Nityananda Zbil on 30.05.24.
//

import APIClient
import Common
import SharedModels

class LectureServiceImpl: LectureService {

    let client = APIClient()

    struct GetLecturesWithSlidesRequest: APIRequest {
        typealias Response = [Lecture]

        let courseId: Int

        var method: HTTPMethod {
            .get
        }

        var resourceName: String {
            "api/lecture/courses/\(courseId)/lectures-with-slides"
        }
    }

    func getLecturesWithSlides(courseId: Int) async -> DataState<[Lecture]> {
        let result = await client.sendRequest(GetLecturesWithSlidesRequest(courseId: courseId))

        switch result {
        case let .success((response, _)):
            return .done(response: response)
        case let .failure(error):
            return .failure(error: UserFacingError(error: error))
        }
    }
}
