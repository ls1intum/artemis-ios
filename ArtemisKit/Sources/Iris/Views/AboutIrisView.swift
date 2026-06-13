//
//  AboutIrisView.swift
//  ArtemisKit
//
//  Created by Senan Aslan on 13.06.26.
//

import DesignLibrary
import SwiftUI

/// Native counterpart to the web client's "About Iris" modal.
struct AboutIrisView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: .l) {
                    header
                    Divider()
                    section(title: R.string.localizable.aboutIrisWhatIrisCanDo(),
                            cards: FeatureCard.whatIrisCanDo)
                    Divider()
                    section(title: R.string.localizable.aboutIrisWhatToExpect(),
                            cards: FeatureCard.whatToExpect)
                    Divider()
                    section(cards: FeatureCard.privacy)
                }
                .padding(.l)
            }
            .navigationTitle(R.string.localizable.aboutIris())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(R.string.localizable.close()) { dismiss() }
                }
            }
        }
        .presentationDragIndicator(.visible)
    }

    private var header: some View {
        VStack(spacing: .m) {
            Image("iris-colored", bundle: .module)
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
            VStack(spacing: .s) {
                Text(R.string.localizable.aboutIrisMeetIris())
                    .font(.title2.bold())
                Text(R.string.localizable.aboutIrisSubtitle())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(R.string.localizable.aboutIrisDescription())
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private func section(title: String? = nil, cards: [FeatureCard]) -> some View {
        VStack(alignment: .leading, spacing: .l) {
            if let title {
                Text(title)
                    .font(.headline)
            }
            ForEach(cards) { card in
                FeatureCardRow(card: card)
            }
        }
    }
}

private struct FeatureCard: Identifiable {
    let title: String
    let description: String
    let footNote: String?
    let systemName: String
    let tint: Color

    var id: String { title }
    
    init(title: String, description: String, footNote: String? = nil, systemName: String, tint: Color) {
        self.title = title
        self.description = description
        self.footNote = footNote
        self.systemName = systemName
        self.tint = tint
    }
}

private extension FeatureCard {
    static var whatIrisCanDo: [FeatureCard] {
        [
            FeatureCard(title: R.string.localizable.aboutIrisContextAwareTitle(),
                        description: R.string.localizable.aboutIrisContextAwareDescription(),
                        systemName: "brain", tint: Color.Artemis.artemisBlue),
            FeatureCard(title: R.string.localizable.aboutIrisGuidedLearningTitle(),
                        description: R.string.localizable.aboutIrisGuidedLearningDescription(),
                        systemName: "lightbulb", tint: Color.Artemis.artemisBlue),
            FeatureCard(title: R.string.localizable.aboutIrisFeedbackHelpsTitle(),
                        description: R.string.localizable.aboutIrisFeedbackHelpsDescription(),
                        systemName: "hand.thumbsup", tint: Color.Artemis.artemisBlue)
        ]
    }

    static var whatToExpect: [FeatureCard] {
        [
            FeatureCard(title: R.string.localizable.aboutIrisGuideNotSolveTitle(),
                        description: R.string.localizable.aboutIrisGuideNotSolveDescription(),
                        systemName: "safari", tint: .indigo),
            FeatureCard(title: R.string.localizable.aboutIrisStayOnTopicTitle(),
                        description: R.string.localizable.aboutIrisStayOnTopicDescription(),
                        systemName: "book", tint: .indigo),
            FeatureCard(title: R.string.localizable.aboutIrisOwnYourWorkTitle(),
                        description: R.string.localizable.aboutIrisOwnYourWorkDescription(),
                        systemName: "person", tint: .indigo)
        ]
    }

    static var privacy: [FeatureCard] {
        [
            FeatureCard(title: R.string.localizable.aboutIrisPrivacyTitle(),
                        description: R.string.localizable.aboutIrisPrivacyDescription(),
                        footNote: R.string.localizable.aboutIrisPrivacyDisclaimer(),
                        systemName: "lock.shield", tint: .green)
        ]
    }
}

private struct FeatureCardRow: View {
    let card: FeatureCard

    var body: some View {
        HStack(alignment: .top, spacing: .m) {
            IconBadge(systemName: card.systemName, tint: card.tint)
            VStack(alignment: .leading, spacing: .xs) {
                Text(card.title)
                    .font(.subheadline.weight(.semibold))
                Text(card.description)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                if let footNote = card.footNote {
                    Text(footNote)
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }
}

private struct IconBadge: View {
    let systemName: String
    let tint: Color

    var body: some View {
        Image(systemName: systemName)
            .font(.headline)
            .foregroundStyle(tint)
            .frame(width: 36, height: 36)
            .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 9))
    }
}
