//
//  File.swift
//  
//
//  Created by Sven Andabaka on 30.04.23.
//

import Foundation
import Common
import SharedModels

protocol LectureService {
    func getLectureDetails(lectureId: Int) async -> DataState<Lecture>
    func getAttachmentFile(link: String) async -> DataState<URL>
    func updateLectureUnitCompletion(lectureId: Int, lectureUnitId: Int64, completed: Bool) async -> NetworkResponse
    func getAssociatedChannel(for lectureId: Int, in courseId: Int) async -> DataState<Channel>
}

enum LectureServiceFactory {
    static let shared: LectureService = LectureServiceImpl()
}
