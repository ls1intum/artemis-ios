//
//  File.swift
//  
//
//  Created by Sven Andabaka on 30.04.23.
//

import Foundation
import Common
import SharedModels

struct LectureAttachmentFile {
    let url: URL
    let studentVersion: Bool
}

protocol LectureService {
    func getLectureDetails(lectureId: Int) async -> DataState<LectureMediaDetails>
    func getAttachmentFile(link: String, name: String?) async -> DataState<LectureAttachmentFile>
    func updateLectureUnitCompletion(lectureId: Int, lectureUnitId: Int64, completed: Bool) async -> NetworkResponse
    func getAssociatedChannel(for lectureId: Int, in courseId: Int) async -> DataState<Channel>
}

enum LectureServiceFactory {
    static let shared: LectureService = LectureServiceImpl()
}

/// Additional attachment access metadata absent from the pinned shared model.
struct LectureMediaDetails: Decodable {
    let lecture: Lecture
    let studentVersions: [Int: String]

    private enum Keys: String, CodingKey { case lectureUnits }
    private struct UnitAccess: Decodable { let attachment: AttachmentAccess? }
    private struct AttachmentAccess: Decodable { let id: Int; let studentVersion: String? }

    init(from decoder: Decoder) throws {
        lecture = try Lecture(from: decoder)
        let container = try decoder.container(keyedBy: Keys.self)
        let units = try container.decodeIfPresent([UnitAccess].self, forKey: .lectureUnits) ?? []
        studentVersions = units.reduce(into: [:]) { result, unit in
            if let attachment = unit.attachment, let version = attachment.studentVersion, !version.isEmpty {
                result[attachment.id] = version
            }
        }
    }
}
