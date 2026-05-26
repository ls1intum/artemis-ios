//
//  SearchFilterType.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 21.03.26.
//

import SharedModels

enum SearchFilterType: String, Codable, ConstantsEnum {
    case exercise
    case lecture
    case lectureUnit = "lecture_unit"
    case exam
    case faq
    case channel
    case course
    case post
    case answerPost = "answer_post"
    case unknown

    /// String describing the type for the API query param
    var apiType: String { rawValue }

    /// Returns how to decode the `metadata` property of the `SearchResultDTO` for the given type
    var codableType: SearchResultDetails.Type? {
        switch self {
        case .exercise:
            ExerciseSearchResult.self
        case .lecture, .lectureUnit:
            LectureSearchResult.self
        case .faq:
            FAQSearchResult.self
        case .channel:
            ChannelSearchResult.self
        case .post, .answerPost:
            PostSearchResult.self
        default:
            nil
        }
    }
}
