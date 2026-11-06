import Foundation

/// Deliberately decodes only the released student fields. Never retain a rubric or assessment note.
struct StudentFeedback: Decodable {
    let id: Int64?
    let text: String?
    var detailText: String?
    let credits: Double?
    let positive: Bool?
    let type: String?
    let reference: String?
    var hasLongFeedbackText: Bool?
    let staticCodeAnalysis: Bool?
    let testCase: TestCase?
    let standardMessage: String?

    struct TestCase: Decodable { let testName: String? }
    private struct PublicInstruction: Decodable { let feedback: String? }
    private enum CodingKeys: String, CodingKey {
        case id, text, detailText, credits, positive, type, reference, hasLongFeedbackText, staticCodeAnalysis, testCase, gradingInstruction
    }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decodeIfPresent(Int64.self, forKey: .id)
        text = try values.decodeIfPresent(String.self, forKey: .text)
        detailText = try values.decodeIfPresent(String.self, forKey: .detailText)
        credits = try values.decodeIfPresent(Double.self, forKey: .credits)
        positive = try values.decodeIfPresent(Bool.self, forKey: .positive)
        type = try values.decodeIfPresent(String.self, forKey: .type)
        reference = try values.decodeIfPresent(String.self, forKey: .reference)
        hasLongFeedbackText = try values.decodeIfPresent(Bool.self, forKey: .hasLongFeedbackText)
        staticCodeAnalysis = try values.decodeIfPresent(Bool.self, forKey: .staticCodeAnalysis)
        testCase = try values.decodeIfPresent(TestCase.self, forKey: .testCase)
        standardMessage = try values.decodeIfPresent(PublicInstruction.self, forKey: .gradingInstruction)?.feedback
    }
    var message: String {
        if let diagnostic { return diagnostic.message ?? detailText ?? "" }
        if let standardMessage, !standardMessage.isEmpty {
            return [standardMessage, detailText, text].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: "\n")
        }
        return detailText?.isEmpty == false ? detailText! : text ?? ""
    }
    struct Diagnostic: Decodable {
        let filePath: String?
        let startLine: Int?
        let endLine: Int?
        let rule: String?
        let message: String?
        let priority: String?
    }
    var diagnostic: Diagnostic? {
        guard group == .staticAnalysis, let detailText else { return nil }
        return try? JSONDecoder().decode(Diagnostic.self, from: Data(detailText.utf8))
    }
    var title: String {
        if group == .staticAnalysis {
            let category = String((text ?? "").dropFirst("SCAFeedbackIdentifier:".count))
            return [category, diagnostic?.rule].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · ")
        }
        if group == .policy { return String((text ?? "").dropFirst("SubPolFeedbackIdentifier:".count)) }
        return testCase?.testName ?? text ?? ""
    }
    var sourceReference: String? {
        if let diagnostic, let file = diagnostic.filePath, let first = diagnostic.startLine, first > 0 {
            let last = max(first, diagnostic.endLine ?? first)
            return "file:\(file)_line:\(first - 1)-\(last - 1)"
        }
        return reference
    }
    enum Group: CaseIterable { case tests, staticAnalysis, manual, policy }
    var group: Group {
        if staticCodeAnalysis == true || text?.hasPrefix("SCAFeedbackIdentifier:") == true { return .staticAnalysis }
        if text?.hasPrefix("SubPolFeedbackIdentifier:") == true { return .policy }
        return type == "AUTOMATIC" || type == "AUTOMATIC_ADAPTED" ? .tests : .manual
    }
}

struct ReviewReference: Hashable, Identifiable {
    let courseID: Int
    let exerciseID: Int
    let participationID: Int
    let submissionID: Int
    let resultID: Int
    var submissionDate: Date?
    var completionDate: Date?
    var rated: Bool?
    var id: String { "\(participationID)/\(submissionID)/\(resultID)" }
}

struct ReviewResult: Decodable {
    let id: Int?
    let score: Double?
    let rated: Bool?
    let completionDate: Date?
    let assessmentType: String?
    var successful: Bool?
    let feedbacks: [StudentFeedback]?
    let testCaseCount: Int?
    let passedTestCaseCount: Int?
    let codeIssueCount: Int?
}
struct ReviewSubmission: Decodable {
    let id: Int?
    let submissionDate: Date?
    let text: String?
    let blocks: [ReviewTextAnchor]?
    let filePath: String?
    let model: String?
    let explanationText: String?
    let commitHash: String?
    let buildFailed: Bool?
    let results: [ReviewResult?]?
}
struct ReviewParticipation: Decodable {
    let id: Int?
    let submissions: [ReviewSubmission]?
    var individualDueDate: Date?
    var testRun: Bool?
    func assessedSubmission(submissionID: Int, resultID: Int) throws -> ReviewSubmission {
        guard let submission = submissions?.first(where: { $0.id == submissionID }),
              submission.results?.contains(where: { $0?.id == resultID }) == true else { throw ReviewError.identity }
        return submission
    }
    func references(courseID: Int, exerciseID: Int) -> [ReviewReference] {
        guard let id else { return [] }
        return (submissions ?? []).flatMap { submission -> [ReviewReference] in
            guard let sid = submission.id else { return [] }
            return (submission.results ?? []).compactMap { result in
                guard let result, let rid = result.id else { return nil }
                return ReviewReference(courseID: courseID, exerciseID: exerciseID, participationID: id, submissionID: sid,
                                       resultID: rid, submissionDate: submission.submissionDate, completionDate: result.completionDate, rated: result.rated)
            }
        }.sorted { ($0.completionDate ?? .distantPast) > ($1.completionDate ?? .distantPast) }
    }
}
struct ReviewTextAnchor: Decodable {
    let id: String?
    let startIndex: Int?
    let endIndex: Int?
    static func range(start: Int, end: Int, in text: String) -> NSRange? {
        guard start >= 0, end > start, end <= text.utf16.count else { return nil }
        let range = NSRange(location: start, length: end - start)
        let units = Array(text.utf16)
        func splitsSurrogate(_ offset: Int) -> Bool {
            offset > 0 && offset < units.count && (0xDC00...0xDFFF).contains(units[offset]) && (0xD800...0xDBFF).contains(units[offset - 1])
        }
        guard !splitsSurrogate(start), !splitsSurrogate(end) else { return nil }
        return range
    }
    static func resolve(reference: String?, blocks: [Self], text: String) -> NSRange? {
        guard let reference else { return nil }
        if let block = blocks.first(where: { $0.id == reference }), let start = block.startIndex, let end = block.endIndex {
            return range(start: start, end: end, in: text)
        }
        if let start = Int(reference), start >= 0, start < text.utf16.count {
            for length in 1...min(8, text.utf16.count - start) {
                if let range = range(start: start, end: start + length, in: text) { return range }
            }
        }
        return nil
    }
}
enum ReviewScore {
    static func rounded(_ value: Double, precision: Int) -> Double {
        guard value.isFinite, let decimal = Decimal(string: String(value), locale: Locale(identifier: "en_US_POSIX")), !decimal.isNaN else { return value }
        var multiplier = Decimal(1)
        for _ in 0..<min(10, max(0, precision)) { multiplier *= 10 }
        // Lodash shifts the decimal exponent before Math.round; a binary multiply loses 1.005's tie.
        // floor(x + 0.5) also preserves Math.round's negative-half direction.
        var shifted = decimal * multiplier + Decimal(1) / 2
        var integer = Decimal()
        NSDecimalRound(&integer, &shifted, 0, .down)
        return Double(NSDecimalNumber(decimal: integer / multiplier).stringValue) ?? value
    }
    static func points(score: Double?, maximum: Double?, precision: Int) -> Double? {
        guard let score, let maximum, score.isFinite, maximum.isFinite else { return nil }
        return rounded(score * maximum / 100, precision: precision)
    }
}
enum ReviewError: Error { case identity, sessionChanged, denied, http(Int), invalidURL }

struct ReviewCodeLocation {
    let file: String
    let firstLine: Int
    let lastLine: Int
    init?(reference: String) {
        guard reference.hasPrefix("file:"), let separator = reference.range(of: "_line:", options: .backwards) else { return nil }
        let file = String(reference.dropFirst(5).prefix(upTo: separator.lowerBound))
        let parts = reference[separator.upperBound...].split(separator: "-", omittingEmptySubsequences: false)
        guard !file.isEmpty, parts.count <= 2, let first = parts.first.flatMap({ Int($0) }), first >= 0 else { return nil }
        let last = parts.count == 2 ? Int(parts[1]) : first
        guard let last, last >= first else { return nil }
        self.file = file; self.firstLine = first; self.lastLine = last
    }
}

enum ReviewDeadline {
    static func isLate(submitted: Date?, due: Date?, individual: Date?) -> Bool? {
        guard let submitted, let deadline = individual ?? due else { return nil }
        return submitted > deadline
    }
}

struct ReviewMessagePreview {
    let full: String
    let collapsed: String
    var isTruncated: Bool { full != collapsed }
    init(_ message: String) {
        full = message
        let firstLines = message.components(separatedBy: "\n").prefix(6).joined(separator: "\n")
        let prefix = String(firstLines.prefix(400))
        collapsed = prefix == message ? message : prefix + "…"
    }
}
