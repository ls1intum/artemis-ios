//
//  File.swift
//  
//
//  Created by Sven Andabaka on 09.01.23.
//

import Foundation

public protocol APIRequest: Codable {
    associatedtype Response: Decodable
    
    var resourceName: String { get }
    var method: HTTPMethod { get }
}

public struct RawResponse: Decodable {
    let rawData: String
}
