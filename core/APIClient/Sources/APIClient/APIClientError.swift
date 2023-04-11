//
//  File.swift
//
//
//  Created by Sven Andabaka on 09.01.23.
//

import Foundation
import Common

public enum APIClientError: Error {
    case jhipsterError(error: UserFacingError)
    case httpURLResponseError(statusCode: HTTPStatusCode?, artemisError: String?)
    case networkError(error: Error)
    case decodingError(error: Error, statusCode: Int)
    case encodingError(error: Error)
    case imageCompressionFailed
    case invalidURL
    case notHTTPResponse
    case wrongParameters
    case other(message: String)

    var title: String {
        switch self {
        case .jhipsterError:
            return "J Hipster Error"
        case .httpURLResponseError:
            return "HTTP Response Error"
        case .networkError:
            return "Network Error"
        case .decodingError:
            return "Decoding Error"
        case .encodingError:
            return "Encoding Error"
        case .imageCompressionFailed:
            return "Image Compression Failed"
        case .invalidURL:
            return "Invalid URL"
        case .notHTTPResponse:
            return "Not a HTTP response"
        case .wrongParameters:
            return "Wrong Parameters"
        case .other:
            return "Error"
        }
    }

    var message: String {
        switch self {
        case .other(let message):
            return message
        case .jhipsterError(let error):
            return error.description
        case let .httpURLResponseError(statusCode, artemisError):
            return "\(artemisError?.description ?? localizedDescription) (Status Code: \(statusCode?.rawValue.description ?? ""))"
        case .networkError(let error):
            return error.localizedDescription
        case .decodingError(let error, _):
            guard let decodingError = error as? DecodingError else {
                return error.localizedDescription
            }
            switch decodingError {
            case .keyNotFound(_, let context):
                return context.debugDescription
            default:
                return decodingError.failureReason ?? decodingError.localizedDescription
            }
        default: return localizedDescription
        }
    }
}

extension APIClientError: Equatable {
    public static func == (lhs: APIClientError, rhs: APIClientError) -> Bool {
        switch (lhs, rhs) {
        case let (.httpURLResponseError(statusCode, artemisError), .httpURLResponseError(statusCode2, artemisError2)):
            return statusCode?.rawValue == statusCode2?.rawValue && artemisError == artemisError2
        default:
            return false
        }
    }
}

public extension DataState {
    init(error: APIClientError) {
        switch error {
        case .jhipsterError(let userFacingError):
            self = .failure(error: userFacingError)
        default:
            self = .failure(error: UserFacingError(error: error))
        }
    }
}

public extension NetworkResponse {
    init(error: APIClientError) {
        self = .failure(error: error)
    }
}

public extension UserFacingError {
    init(error: APIClientError) {
        switch error {
        case .jhipsterError(let error):
            self = error
        default:
            self.init(title: error.title)
            self.message = error.message
        }
    }
}
