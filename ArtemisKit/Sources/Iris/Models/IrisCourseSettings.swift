//
//  IrisCourseSettings.swift
//  ArtemisKit
//
//  Created by Senan Aslan on 09.05.26.
//

import SharedModels

/// Pipeline variant selection for Iris (admin-only configuration).
/// Server uses lowercase strings via `@JsonValue`.
enum IrisPipelineVariant: String, ConstantsEnum {
    case `default`
    case advanced
    case unknown
}

/// Per-course rate limit. Both fields are optional:
/// - `nil` (whole struct missing) → use application defaults.
/// - present but with both fields `nil` (i.e. `{}`) → explicitly unlimited.
struct IrisRateLimitConfiguration: Codable, Hashable {
    let requests: Int?
    let timeframeHours: Int?
}

/// Editable course-level Iris settings (`course_iris_settings` JSON column).
/// Note: `customInstructions` has a server-enforced max of 2048 characters.
struct IrisCourseSettingsDTO: Codable, Hashable {
    let enabled: Bool
    let customInstructions: String?
    let variant: IrisPipelineVariant
    let rateLimit: IrisRateLimitConfiguration?
}

/// Full settings response from `GET /courses/{courseId}/iris-settings`.
/// Combines the editable settings with the server-computed effective limits.
struct IrisCourseSettingsWithRateLimitDTO: Codable, Hashable {
    let courseId: Int
    let settings: IrisCourseSettingsDTO
    let effectiveRateLimit: IrisRateLimitConfiguration
    let applicationRateLimitDefaults: IrisRateLimitConfiguration
}
