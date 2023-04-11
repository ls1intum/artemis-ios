//
//  DisplayPriority.swift
//  
//
//  Created by Sven Andabaka on 06.04.23.
//

/**
 * The priority with which a post is shown in a list, PINNED represents a high priority, whereas ARCHIVED low priority.
 */
public enum DisplayPriority: String, RawRepresentable, Codable {
    case pinned = "PINNED"
    case archived = "ARCHIVED"
    case noInformation = "NONE"
}
