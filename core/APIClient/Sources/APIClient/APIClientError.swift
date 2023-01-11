//
//  File.swift
//  
//
//  Created by Sven Andabaka on 09.01.23.
//

import Foundation

public enum APIClientError: Error {
    case httpURLResponseError(statusCode: HTTPStatusCode?)
    case networkError(error: Error)
    case decodingError(error: Error, statusCode: Int)
    case encodingError(error: Error)
    case imageCompressionFailed
    case invalidURL
    case notHTTPResponse
    case wrongParameters
    case noRedirectLinkPayment
    case other(message: String)

    var message: String {
        switch self {
        case .other(message: let message): return message
        default: return localizedDescription
        }
    }
}

extension APIClientError: Equatable {
    public static func == (lhs: APIClientError, rhs: APIClientError) -> Bool {
        switch (lhs, rhs) {
        case let (.httpURLResponseError(statusCode), .httpURLResponseError(statusCode2)):
            return statusCode?.rawValue == statusCode2?.rawValue
        default:
            return false
        }
    }
}
