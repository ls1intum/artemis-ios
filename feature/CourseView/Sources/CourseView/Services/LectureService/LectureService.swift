//
//  File.swift
//  
//
//  Created by Sven Andabaka on 30.04.23.
//

import Foundation
import Common
import Dependencies
import SharedModels

protocol LectureService {
    func getLectureDetails(lectureId: Int) async -> DataState<Lecture>
    func getAttachmentFile(link: String) async -> DataState<URL>
    func updateLectureUnitCompletion(lectureId: Int, lectureUnitId: Int64, completed: Bool) async -> NetworkResponse
}

enum LectureServiceFactory {
    static let shared: LectureService = LectureServiceImpl()
}

// MARK: - LectureService

enum LectureServiceKey: DependencyKey {
    typealias Value = LectureService

    static var liveValue: Value {
        LectureServiceFactory.shared
    }
}

extension DependencyValues {
    var lectureService: LectureService {
        get {
            self[LectureServiceKey.self]
        }
        set {
            self[LectureServiceKey.self] = newValue
        }
    }
}
