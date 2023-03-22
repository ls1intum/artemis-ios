//
//  UnknownSubmission.swift
//  
//
//  Created by Sven Andabaka on 21.03.23.
//

import Foundation

public struct UnknownSubmission: BaseSubmission {
    public static var type: String {
        "unknown"
    }

    public var id: Int?
    public var submitted: Bool?
    public var submissionDate: Date?
    public var exampleSubmission: Bool?
    public var durationInMinutes: Double?
    public var results: [Result]?
    public var participation: Participation?
}
