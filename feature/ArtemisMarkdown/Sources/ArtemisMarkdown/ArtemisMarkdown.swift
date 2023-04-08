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
        let replacedText = replaceExercises(replaceType: .text, replacedQuiz)
        let replacedModeling = replaceExercises(replaceType: .modeling, replacedText)
        let replacedFileUpload = replaceExercises(replaceType: .fileUpload, replacedModeling)
        let replacedLecture = replaceLecture(replacedFileUpload)
        let replacedInsTag = replaceInsTag(replacedLecture)
        return replacedInsTag
    }

    public var body: some View {
        Markdown(markdownString)
            .markdownTheme(.gitHub)
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

    private func replaceInsTag(_ input: String) -> String {
        let regex = try! NSRegularExpression(pattern: "<ins>(.*?)</ins>")
        let replacement = "$1"
        return regex.stringByReplacingMatches(in: input, range: NSRange(input.startIndex..., in: input), withTemplate: replacement)
    }

    enum ReplaceType: String, RawRepresentable {
        case programming
        case quiz
        case text
        case fileUpload = "file-upload"
        case modeling

        var altText: String {
            switch self {
            case .programming:
                return "Programming"
            case .quiz:
                return "Quiz"
            case .text:
                return "Text"
            case .fileUpload:
                return "File Upload"
            case .modeling:
                return "Modeling"
            }
        }

        var icon: String {
            switch self {
            case .programming:
                return "fa-keyboard"
            case .quiz:
                return "fa-check-double"
            // TODO
            default:
                return "fa-check-double"
            }
        }
    }
}
