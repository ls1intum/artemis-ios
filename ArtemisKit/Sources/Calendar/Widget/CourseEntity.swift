//
//  Course.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 29.04.26.
//

import APIClient
import AppIntents
import SharedServices

public struct Course: AppEntity {
    public let id: Int
    let name: String

    public static var typeDisplayRepresentation: TypeDisplayRepresentation = "Course"
    public static var defaultQuery = CourseQuery()

    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

public struct CourseQuery: EntityQuery {
    public init() {}

    public func entities(for identifiers: [Course.ID]) async throws -> [Course] {
        try await suggestedEntities().filter { identifiers.contains($0.id) }
    }

    public func suggestedEntities() async throws -> [Course] {

        APIClient.setupCurrentJWT()

        let coursesInfo = await CourseServiceFactory.shared.getCourses()
        switch coursesInfo {
        case .done(let info):
            return (info.courses ?? []).map {
                Course(id: $0.id, name: $0.course.title ?? "" )
            }
        case .failure(let error):
            throw error
        default:
            throw URLError(.fileDoesNotExist)
        }
    }
}
