//
//  LectureService.swift
//
//
//  Created by Nityananda Zbil on 30.05.24.
//

import Common
import SharedModels

protocol LectureService {
    func getLecturesWithSlides(courseId: Int) async -> DataState<[Lecture]>
    func getLectureDetailsWithSlides(lectureId: Int) async -> DataState<Lecture>
}

enum LectureServiceFactory {
    static let shared: LectureService = LectureServiceImpl()
}
