import Foundation
import CryptoKit

/// URLs with embedded credentials and non-network schemes never enter a media view.
enum LectureMediaSource: Equatable {
    case video, web, invalid

    static func classify(_ url: URL, mimeType: String? = nil) -> Self {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              ["http", "https"].contains(components.scheme?.lowercased() ?? ""),
              components.host?.isEmpty == false, components.user == nil, components.password == nil else { return .invalid }
        let mime = mimeType?.lowercased().split(separator: ";").first.map(String.init)
        if ["video/mp4", "application/vnd.apple.mpegurl", "application/x-mpegurl"].contains(mime ?? "") { return .video }
        return ["mp4", "m3u8"].contains(url.pathExtension.lowercased()) ? .video : .web
    }
}

enum LectureMediaOrigin {
    static func normalized(_ url: URL) -> String? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let scheme = components.scheme?.lowercased(), ["http", "https"].contains(scheme),
              let host = components.host?.lowercased(), !host.isEmpty,
              components.user == nil, components.password == nil else { return nil }
        return "\(scheme)://\(host):\(components.port ?? (scheme == "https" ? 443 : 80))"
    }

    static func matches(_ left: URL, _ right: URL) -> Bool {
        guard let origin = normalized(left) else { return false }
        return origin == normalized(right)
    }
}

struct LectureMediaRequestPolicy {
    let origin: URL
    let token: String?

    func request(for url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpShouldHandleCookies = false
        if LectureMediaOrigin.matches(origin, url), let token {
            request.setValue("jwt=\(token)", forHTTPHeaderField: "Cookie")
        }
        return request
    }

    /// Rebuild each redirect; credentials never follow a change of origin.
    /// An external redirect back to Artemis cannot acquire credentials.
    func redirect(from source: URL, to destination: URL) -> URLRequest? {
        guard LectureMediaSource.classify(destination) != .invalid else { return nil }
        var redirected = request(for: destination)
        if !LectureMediaOrigin.matches(origin, source) { redirected.setValue(nil, forHTTPHeaderField: "Cookie") }
        return redirected
    }
}

struct LectureMediaProgress {
    private let key: String
    private let defaults: UserDefaults

    init(account: String, server: URL, identity: String, defaults: UserDefaults = .standard) {
        // Callers use stable model IDs, never signed URLs. Hash all identity components
        // so neither account names nor resource paths become preference keys.
        let data = Data("\(account.utf8.count):\(account)|\(LectureMediaOrigin.normalized(server) ?? "invalid")|\(identity)".utf8)
        key = "lectureMedia." + SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        self.defaults = defaults
    }

    var seconds: Double { max(0, defaults.double(forKey: key + ".seconds")) }

    func save(seconds: Double) {
        guard seconds.isFinite, seconds >= 0 else { return }
        defaults.set(seconds, forKey: key + ".seconds")
    }

    func save(page: Int) { defaults.set(max(0, page), forKey: key + ".page") }

    func pageIndex(explicitPage: Int?, pageCount: Int) -> Int {
        let requested = explicitPage.map { $0 <= 1 ? 0 : $0 - 1 } ?? defaults.integer(forKey: key + ".page")
        return min(max(0, requested), max(0, pageCount - 1))
    }
}

struct LectureMediaLoadGeneration {
    private var current = UUID()
    mutating func begin() -> UUID { current = UUID(); return current }
    mutating func cancel() { current = UUID() }
    func accepts(_ generation: UUID) -> Bool { current == generation }
}

enum LectureMediaPlaylist {
    enum Failure: Error { case unsupported }

    static func rewrite(_ playlist: String, relativeTo base: URL, map: (URL) throws -> URL) throws -> String {
        guard playlist.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("#EXTM3U"),
              !playlist.contains("{$"), !playlist.contains("#EXT-X-CONTENT-STEERING"),
              !playlist.contains("METHOD=SAMPLE-AES"), !playlist.contains("KEYFORMAT="),
              !playlist.contains("#EXT-X-PART"), !playlist.contains("#EXT-X-PRELOAD-HINT"),
              !playlist.contains("#EXT-X-RENDITION-REPORT"), !playlist.contains("#EXT-X-SERVER-CONTROL"),
              !playlist.contains("#EXT-X-DEFINE"), !playlist.contains("#EXT-X-DATERANGE") else { throw Failure.unsupported }
        let supportedTags: Set<String> = [
            "#EXTM3U", "#EXT-X-VERSION", "#EXT-X-INDEPENDENT-SEGMENTS", "#EXT-X-START", "#EXTINF",
            "#EXT-X-BYTERANGE", "#EXT-X-DISCONTINUITY", "#EXT-X-KEY", "#EXT-X-MAP", "#EXT-X-PROGRAM-DATE-TIME",
            "#EXT-X-GAP", "#EXT-X-TARGETDURATION", "#EXT-X-MEDIA-SEQUENCE", "#EXT-X-DISCONTINUITY-SEQUENCE",
            "#EXT-X-ENDLIST", "#EXT-X-PLAYLIST-TYPE", "#EXT-X-I-FRAMES-ONLY", "#EXT-X-MEDIA",
            "#EXT-X-STREAM-INF", "#EXT-X-I-FRAME-STREAM-INF", "#EXT-X-SESSION-DATA", "#EXT-X-SESSION-KEY", "#EXT-X-ALLOW-CACHE"
        ]
        let expression = try NSRegularExpression(pattern: #"URI="([^"]+)""#)
        func rewriteURL(_ raw: String) throws -> String {
            guard let url = URL(string: raw, relativeTo: base)?.absoluteURL,
                  LectureMediaSource.classify(url) != .invalid else { throw Failure.unsupported }
            return try map(url).absoluteString
        }
        return try playlist.components(separatedBy: .newlines).map { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { return line }
            if !trimmed.hasPrefix("#") { return try rewriteURL(trimmed) }
            let tag = String(trimmed.split(separator: ":", maxSplits: 1).first ?? "")
            if tag.hasPrefix("#EXT"), !supportedTags.contains(tag) { throw Failure.unsupported }
            let range = NSRange(line.startIndex..., in: line)
            let withoutURIs = expression.stringByReplacingMatches(in: line, range: range, withTemplate: "")
            guard !withoutURIs.contains("URI=") else { throw Failure.unsupported }
            var rewritten = line
            let matches = expression.matches(in: line, range: NSRange(line.startIndex..., in: line))
            for match in matches.reversed() {
                guard let valueRange = Range(match.range(at: 1), in: line),
                      let replacementRange = Range(match.range(at: 1), in: rewritten) else { throw Failure.unsupported }
                rewritten.replaceSubrange(replacementRange, with: try rewriteURL(String(line[valueRange])))
            }
            return rewritten
        }.joined(separator: "\n")
    }
}

enum LectureMediaProxyRequest {
    static func validRange(_ value: String) -> Bool {
        guard value.hasPrefix("bytes="), value.count < 80 else { return false }
        let parts = value.dropFirst(6).split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 2, !parts.allSatisfy({ $0.isEmpty }),
              parts.allSatisfy({ $0.allSatisfy(\.isNumber) }) else { return false }
        if !parts[0].isEmpty && Int64(parts[0]) == nil { return false }
        if !parts[1].isEmpty && Int64(parts[1]) == nil { return false }
        if let start = Int64(parts[0]), let end = Int64(parts[1]) { return start <= end }
        return true
    }
}

enum LectureMediaSlidePage {
    static func documentIndex(page: Int, pageCount: Int) -> Int? {
        guard page >= 1, page <= pageCount else { return nil }
        return page - 1
    }

    static func page(original: Int, visibleNumbers: [Int], studentVersion: Bool) -> Int? {
        let visible = Array(Set(visibleNumbers.filter { $0 > 0 })).sorted()
        guard let index = visible.firstIndex(of: original) else { return nil }
        return studentVersion ? index + 1 : original
    }
}
