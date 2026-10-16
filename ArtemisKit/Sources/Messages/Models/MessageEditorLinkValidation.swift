import Foundation

/// Only navigable web/mail links and server-relative Artemis paths are offered by the link UI.
enum MessageEditorLinkValidation {
    static func isValid(_ address: String) -> Bool {
        let decoded = address.removingPercentEncoding ?? address
        guard !address.isEmpty, address.rangeOfCharacter(from: .whitespacesAndNewlines.union(.controlCharacters)) == nil,
              decoded.rangeOfCharacter(from: .controlCharacters) == nil,
              !decoded.contains("\\"), let url = URL(string: address) else { return false }
        if address.hasPrefix("/api/") || address.hasPrefix("/courses/") { return url.scheme == nil && url.host == nil }
        switch url.scheme?.lowercased() {
        case "https", "http": return !(url.host?.isEmpty ?? true)
        case "mailto": return !url.path.isEmpty
        default: return false
        }
    }
}
