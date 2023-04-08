import SwiftUI
import MarkdownUI
import UserStore

public struct ArtemisMarkdownView: View {

    let string: String

    public init(string: String) {
        self.string = string
    }

    private var markdownString: String {
        let replacedProgramming = replaceExercises(replaceType: .programming, string)
        let replacedQuiz = replaceExercises(replaceType: .quiz, replacedProgramming)
        let replacedLecture = replaceLecture(replacedQuiz)
        return replacedLecture
    }

    public var body: some View {
        Markdown(markdownString)
            .markdownTextStyle(\.code) {
                FontFamilyVariant(.monospaced)
                ForegroundColor(.red)
            }
            .markdownImageProvider(AssetImageProvider(bundle: .module))
            .markdownInlineImageProvider(AssetInlineImageProvider(bundle: .module))
    }

    // swiftlint:disable force_try
    private func replaceExercises(replaceType: ReplaceType, _ inputString: String) -> String {
        guard let baseURL = UserSession.shared.institution?.baseURL?.absoluteString else { return inputString }

        let pattern = "\\[\(replaceType.rawValue)\\](.*?)\\(/courses/(\\d+)/exercises/(\\d+)\\)\\[/\(replaceType.rawValue)\\]"
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(inputString.startIndex..<inputString.endIndex, in: inputString)

        let outputString = regex.stringByReplacingMatches(in: inputString, options: [], range: range, withTemplate: {
            let title = replaceType.altText
            let icon = replaceType.icon
            let url = "\(baseURL)/courses/$2/exercises/$3"

            return "![\(title)](\(icon)) [$1](\(url))"
        }())

        return outputString
    }

    private func replaceLecture(_ inputString: String) -> String {
        guard let baseURL = UserSession.shared.institution?.baseURL?.absoluteString else { return inputString }

        let pattern = "\\[lecture\\](.*?)\\(/courses/(\\d+)/lectures/(\\d+)\\)\\[/lecture\\]"
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(inputString.startIndex..<inputString.endIndex, in: inputString)

        let outputString = regex.stringByReplacingMatches(in: inputString, options: [], range: range, withTemplate: {
            let title = "Lecture"
            let icon = "fa-chalkboard-user"
            let url = "\(baseURL)/courses/$2/lectures/$3"

            return "![\(title)](\(icon)) [$1](\(url))"
        }())

        return outputString
    }

    enum ReplaceType: String, RawRepresentable {
        case programming
        case quiz

        var altText: String {
            switch self {
            case .programming:
                return "Programming"
            case .quiz:
                return "Quiz"
            }
        }

        var icon: String {
            switch self {
            case .programming:
                return "fa-keyboard"
            case .quiz:
                return "fa-check-double"
            }
        }
    }
}
