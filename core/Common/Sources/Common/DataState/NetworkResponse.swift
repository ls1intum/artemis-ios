import Foundation

/**
 * Wrapper around network responses. Used to propagate failures correctly.
 */
public enum NetworkResponse {
    case notStarted
    case loading
    case success
    case failure(error: Error)
}
