import Foundation
import Navigation
import SharedModels

/// Preserve a modern slide reference as a link instead of an image-only preview.
/// The stored message and composer source remain unchanged.
enum LectureSlideReference {
    static func rendering(_ source: String) -> String {
        source.replacing(#/\[slide\](?<title>[^\n]*?)\(\#(?<id>\d+)\)\[/slide\]/#) { match in
            let title = String(match.title)
                .replacingOccurrences(of: "[", with: "\\[")
                .replacingOccurrences(of: "]", with: "\\]")
            return "[\(title)](mention://slide-id/\(match.id))"
        }
    }

    static func resolve(slideId: Int?, unitId: Int64?, number: Int?, lectures: [Lecture]) -> (lecture: Lecture, target: LectureMediaTarget)? {
        for lecture in lectures {
            for unit in lecture.lectureUnits ?? [] {
                guard case .attachmentVideo(let attachment) = unit, unitId == nil || unit.id == unitId else { continue }
                let slides = attachment.slides ?? []
                guard let slide = slides.first(where: { slideId != nil ? $0.id == slideId : $0.slideNumber == number }),
                      let original = slide.slideNumber else { continue }
                return (lecture, LectureMediaTarget(unitId: unit.id, originalSlideNumber: original,
                                                    visibleSlideNumbers: slides.compactMap(\.slideNumber).sorted()))
            }
        }
        return nil
    }
}
