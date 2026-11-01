import Foundation
import SwiftUI

public enum ReviewAssetError: Error { case unavailable, foreignOrigin, sessionChanged, invalidImage }

/// A review-owned capability. Its loader must use captured credentials, no redirects and no cache.
/// This module never consults the global institution, cookies, image downloader or image cache.
public final class ReviewAssetContext {
    public let id = UUID()
    public let baseURL: URL
    private let current: () -> Bool
    private let didFail: (Error) -> Void
    private let load: (String) async throws -> Data
    public init(baseURL: URL, isCurrent: @escaping () -> Bool, load: @escaping (String) async throws -> Data, didFail: @escaping (Error) -> Void = { _ in }) {
        self.baseURL = baseURL; self.current = isCurrent; self.load = load; self.didFail = didFail
    }
    public var isCurrent: Bool { current() }
    public func resolve(_ path: String, filePath: Bool = false) throws -> URL {
        let normalized: String
        if filePath, !path.hasPrefix("/"), !path.hasPrefix("api/"), URL(string: path)?.scheme == nil {
            normalized = "/api/core/files/" + path
        } else { normalized = path }
        guard let url = URL(string: normalized, relativeTo: baseURL)?.absoluteURL,
              ["http", "https"].contains(url.scheme), url.scheme == baseURL.scheme, url.host == baseURL.host, url.port == baseURL.port,
              url.user == nil, url.password == nil else { throw ReviewAssetError.foreignOrigin }
        return url
    }
    public func data(path: String, filePath: Bool = false) async throws -> Data {
        do {
            guard isCurrent else { throw ReviewAssetError.sessionChanged }
            let url = try resolve(path, filePath: filePath)
            let data = try await load(url.absoluteString)
            guard isCurrent, !Task.isCancelled else { throw ReviewAssetError.sessionChanged }
            return data
        } catch { didFail(error); throw error }
    }
}

private struct ReviewAssetsKey: EnvironmentKey { static let defaultValue: ReviewAssetContext? = nil }
public extension EnvironmentValues {
    var reviewAssets: ReviewAssetContext? {
        get { self[ReviewAssetsKey.self] }
        set { self[ReviewAssetsKey.self] = newValue }
    }
}
