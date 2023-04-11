//
//  CourseWideContext.swift
//  
//
//  Created by Sven Andabaka on 06.04.23.
//

import Foundation

/**
 * The CourseWideContext enumeration for linking posts to other contexts besides certain exercises or lectures.
 */
public enum CourseWideContext: String, RawRepresentable, Codable {
    case techSupport = "TECH_SUPPORT"
    case organization = "ORGANIZATION"
    case random = "RANDOM"
    case announcement = "ANNOUNCEMENT"
}
