//
//  CourseRegistrationServiceStub.swift
//
//
//  Created by Nityananda Zbil on 18.03.24.
//

import Common
import SharedModels

struct CourseRegistrationServiceStub: CourseRegistrationService {
    func fetchRegistrableCourses() async -> DataState<[Course]> {
        .done(response: [])
    }

    func registerInCourse(courseId: Int) async -> NetworkResponse {
        .loading
    }
}
