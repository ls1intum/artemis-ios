import ReviewContent
import SwiftUI
import UIKit

struct AssessedTextView: UIViewRepresentable {
    let text: String
    let blocks: [ReviewTextAnchor]
    let feedback: [StudentFeedback]
    let selected: Int?
    let onSelect: (Int) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onSelect: onSelect) }
    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.delegate = context.coordinator
        view.isEditable = false
        view.isSelectable = true
        view.isScrollEnabled = true
        view.backgroundColor = .clear
        view.adjustsFontForContentSizeCategory = true
        view.textContainerInset = .zero
        view.textContainer.lineFragmentPadding = 0
        view.linkTextAttributes = [.foregroundColor: UIColor.label, .underlineStyle: NSUnderlineStyle.single.rawValue]
        return view
    }
    func updateUIView(_ view: UITextView, context: Context) {
        context.coordinator.onSelect = onSelect
        let value = NSMutableAttributedString(string: text, attributes: [.font: UIFont.preferredFont(forTextStyle: .body), .foregroundColor: UIColor.label])
        for (index, item) in feedback.enumerated() {
            if let range = ReviewTextAnchor.resolve(reference: item.reference, blocks: blocks, text: text) {
                value.addAttributes([.backgroundColor: UIColor.systemYellow.withAlphaComponent(0.22),
                                     .link: URL(string: "artemis-feedback://\(index)")!], range: range)
            }
        }
        if let selected, feedback.indices.contains(selected),
           let range = ReviewTextAnchor.resolve(reference: feedback[selected].reference, blocks: blocks, text: text) {
            value.addAttribute(.backgroundColor, value: UIColor.systemOrange.withAlphaComponent(0.4), range: range)
        }
        view.attributedText = value
        view.accessibilityLabel = ReviewCopy.text("review.assessedAnswer")
        if context.coordinator.selected != selected, let selected, feedback.indices.contains(selected),
           let range = ReviewTextAnchor.resolve(reference: feedback[selected].reference, blocks: blocks, text: text) {
            view.layoutIfNeeded()
            view.scrollRangeToVisible(range)
        }
        context.coordinator.selected = selected
    }
    final class Coordinator: NSObject, UITextViewDelegate {
        var selected: Int?
        var onSelect: (Int) -> Void
        init(onSelect: @escaping (Int) -> Void) { self.onSelect = onSelect }
        func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
            if URL.scheme == "artemis-feedback", let host = URL.host, let index = Int(host) { onSelect(index) }
            return false
        }
    }
}

struct FeedbackReviewRow: View {
    let feedback: StudentFeedback
    let selected: Bool
    let loading: Bool
    let failed: Bool
    let referenceLabel: String?
    let unlocated: Bool
    let onSelect: () -> Void
    let onLong: () -> Void
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                if let positive = feedback.positive {
                    Image(systemName: positive ? "checkmark.circle" : "exclamationmark.circle")
                        .accessibilityLabel(ReviewCopy.text(positive ? "review.positive" : "review.negative"))
                } else { Image(systemName: "text.bubble").accessibilityLabel(ReviewCopy.text("review.neutral")) }
                Text(feedback.title.isEmpty ? ReviewCopy.text("review.feedback") : feedback.title).font(.headline)
                Spacer(minLength: 4)
                if let credits = feedback.credits { Text("\(credits.formatted()) \(ReviewCopy.text("review.points"))").font(.subheadline).monospacedDigit() }
            }
            let preview = ReviewMessagePreview(feedback.message)
            if feedback.hasLongFeedbackText == true {
                if loading { ProgressView() } else {
                    Button(ReviewCopy.text(failed ? "review.retryLong" : "review.fullMessage"), action: onLong)
                        .buttonStyle(.borderless).frame(minHeight: 44)
                }
                if failed { Text(ReviewCopy.text("review.longError")).font(.caption).foregroundStyle(.secondary) }
            } else if preview.isTruncated {
                Button(ReviewCopy.text(expanded ? "review.collapseMessage" : "review.expandMessage")) { expanded.toggle() }
                    .buttonStyle(.borderless).frame(minHeight: 44)
            }
            if expanded || !preview.isTruncated {
                SafeReviewContent(preview.full).textSelection(.enabled)
            } else {
                Text(preview.collapsed).lineLimit(6).textSelection(.enabled)
            }
            if let referenceLabel {
                Button(action: onSelect) {
                    Label(referenceLabel, systemImage: "scope").font(.callout).lineLimit(3).frame(minHeight: 44, alignment: .leading)
                }.buttonStyle(.borderless)
            }
            if unlocated { Text(ReviewCopy.text("review.unlocated")).font(.caption).foregroundStyle(.secondary) }
        }
        .padding(.vertical, 8)
        .listRowBackground(selected ? Color(uiColor: .tertiarySystemFill) : Color(uiColor: .secondarySystemGroupedBackground))
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .onChange(of: feedback.hasLongFeedbackText) { oldValue, newValue in
            if oldValue == true && newValue != true { expanded = true }
        }
    }
}

struct ReviewBuildLog: Decodable { let time: String?; let log: String? }

struct ReviewCodeText: View {
    let text: String
    let location: ReviewCodeLocation?
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView([.horizontal, .vertical]) {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(text.components(separatedBy: "\n").enumerated()), id: \.offset) { index, line in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(index + 1)").foregroundStyle(.secondary).frame(minWidth: 36, alignment: .trailing)
                            Text(line.isEmpty ? " " : line).textSelection(.enabled)
                        }
                        .font(.system(.body, design: .monospaced))
                        .padding(.vertical, 3).padding(.horizontal, 6)
                        .background(location.map { ($0.firstLine...$0.lastLine).contains(index) } == true ? Color(uiColor: .tertiarySystemFill) : .clear)
                        .id(index)
                    }
                }
            }
            .frame(height: 420)
            .onAppear { if let location { proxy.scrollTo(location.firstLine, anchor: .center) } }
            .onChange(of: location?.firstLine) { _, line in if let line { proxy.scrollTo(line, anchor: .center) } }
        }
    }
}
