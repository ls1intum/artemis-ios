//
//  File.swift
//  
//
//  Created by Sven Andabaka on 30.04.23.
//

import Foundation
import Common
import SharedModels
import Navigation

struct LectureAttachmentFile {
    let url: URL
    let studentVersion: Bool
}

protocol LectureService {
    func getLecturesWithSlides(courseId: Int) async -> DataState<[LectureMediaDetails]>
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

struct LectureSlideAccess {
    let attachment: Attachment
    let studentVersion: String?
    let originalSlideNumber: Int
    let visibleSlideNumbers: [Int]

    static func resolve(target: LectureMediaTarget, before: LectureMediaDetails,
                        projection: LectureMediaDetails, after: LectureMediaDetails) -> Self? {
        guard let previous = attachment(target: target, details: before),
              let current = attachment(target: target, details: after),
              previous.id == current.id, previous.link == current.link,
              previous.version == current.version, previous.uploadDate == current.uploadDate,
              before.studentVersions[previous.id] == after.studentVersions[current.id],
              let visible = resolve(target: target, details: projection),
              visible.attachment.id == current.id,
              visible.attachment.link == nil || visible.attachment.link == current.link,
              visible.attachment.version == nil || visible.attachment.version == current.version,
              visible.attachment.uploadDate == nil || visible.attachment.uploadDate == current.uploadDate,
              visible.studentVersion == nil || visible.studentVersion == after.studentVersions[current.id] else { return nil }
        return Self(attachment: current, studentVersion: after.studentVersions[current.id],
                    originalSlideNumber: visible.originalSlideNumber, visibleSlideNumbers: visible.visibleSlideNumbers)
    }

    private static func attachment(target: LectureMediaTarget, details: LectureMediaDetails) -> Attachment? {
        guard let unit = target.resolve(in: details.lecture.lectureUnits ?? []),
              case .attachmentVideo(let attachment) = unit else { return nil }
        return attachment.attachment
    }

    static func resolve(target: LectureMediaTarget, details: LectureMediaDetails) -> Self? {
        guard let unit = target.resolve(in: details.lecture.lectureUnits ?? []),
              case .attachmentVideo(let attachmentUnit) = unit,
              let attachment = attachmentUnit.attachment else { return nil }
        let slides = attachmentUnit.slides ?? []
        let slide = slides.first { candidate in
            if let id = target.slideId { return candidate.id == id }
            return candidate.slideNumber == target.originalSlideNumber
        }
        guard let original = slide?.slideNumber else { return nil }
        return Self(attachment: attachment, studentVersion: details.studentVersions[attachment.id],
                    originalSlideNumber: original, visibleSlideNumbers: slides.compactMap(\.slideNumber).sorted())
    }
}
