import SwiftUI

/// Keeps the read-only diagram mounted while the surrounding review changes layout.
struct ReviewModelPanes<Work: View, Feedback: View>: View {
    let wide: Bool
    let feedbackWidth: CGFloat
    @Binding var section: Int
    @ViewBuilder let work: () -> Work
    @ViewBuilder let feedback: () -> Feedback

    var body: some View {
        VStack(spacing: 0) {
            if !wide {
                Picker(ReviewCopy.text("review.section"), selection: $section) {
                    Text(ReviewCopy.text("review.work")).tag(0)
                    Text(ReviewCopy.text("review.feedback")).tag(1)
                }.pickerStyle(.segmented).padding()
            }
            let layout = wide ? AnyLayout(HStackLayout(alignment: .top, spacing: 0)) : AnyLayout(ZStackLayout(alignment: .topLeading))
            layout {
                work().frame(maxWidth: .infinity)
                    .opacity(wide || section == 0 ? 1 : 0)
                    .allowsHitTesting(wide || section == 0)
                    .accessibilityHidden(!wide && section != 0)
                Divider().frame(width: wide ? 1 : 0).opacity(wide ? 1 : 0)
                    .accessibilityHidden(true)
                feedback().frame(width: wide ? feedbackWidth : nil)
                    .opacity(wide || section == 1 ? 1 : 0)
                    .allowsHitTesting(wide || section == 1)
                    .accessibilityHidden(!wide && section != 1)
            }
        }
    }
}
