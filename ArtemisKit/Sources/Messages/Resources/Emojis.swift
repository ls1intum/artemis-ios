//
//  Emojis.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 20.03.25.
//

import Smile

/// Adds support for emojis unavailable in Smile.
struct Emojis {
    static let all = Smile.emojiList.merging(newEmojis.mapValues { $0.emoji }) { _, newer in newer }

    // Emojis newer than our Smile version, we need to add them manually
    private static let newEmojis: [String: (emoji: String, category: Category)] = [
        "melting_face": ("🫠", .smileys),
        "face_with_open_eyes_and_hand_over_mouth": ("🫢", .smileys),
        "face_with_peeking_eye": ("🫣", .smileys),
        "saluting_face": ("🫡", .smileys),
        "dotted_line_face": ("🫥", .smileys),
        "face_with_diagonal_mouth": ("🫤", .smileys),
        "face_holding_back_tears": ("🥹", .smileys),
        "rightwards_hand": ("🫱", .people),
        "palm_up_hand": ("🫴", .people),
        "hand_with_index_finger_and_thumb_crossed": ("🫰", .people),
        "index_pointing_at_the_viewer": ("🫵", .people),
        "heart_hands": ("🫶", .people),
        "biting_lip": ("🫦", .people),
        "person_with_crown": ("🫅", .people),
        "pregnant_man": ("🫃", .people),
        "pregnant_person": ("🫄", .people),
        // Unicode 15.0 Emojis: "🫨", "🫷", "🫸"
        "troll": ("🧌", .people),
        "coral": ("🪸", .nature),
        "lotus": ("🪷", .nature),
        "empty_nest": ("🪹", .nature),
        "nest_with_eggs": ("🪺", .nature),
        "beans": ("🫘", .food),
        // Unicode 15.0 Eat/Nature:"🕴", "🫎", "🫏", "🐿", "🪽", "🪿", "🪼", "🪻", "🫚", "🫛"
        "pouring_liquid": ("🫗", .food),
        "jar": ("🫙", .food),
        "mirror_ball": ("🪩", .activities),
        "low_battery": ("🪫", .objects),
        "crutch": ("🩼", .objects),
        "x-ray": ("🩻", .objects),
        "bubbles": ("🫧", .objects),
        "identification_card": ("🪪", .objects),
        "heavy_equals_sign": ("🟰", .symbols)
        // Unicode 15.0 Travel/Objects: "🛝", "🛞", "🛟", "🪭", "🪮", "🪇", "🪈", "🪬", "🩷", "🩵", "🩶", "⚠", "🪯", "🛜"
    ]

    static func getEmojiId(for emoji: String) -> String? {
        Smile.alias(emoji: emoji) ?? newEmojis.first(where: { $0.value.emoji == emoji })?.key
    }

    static func getEmoji(for id: String) -> String? {
        Smile.emoji(alias: id) ?? newEmojis[id]?.emoji
    }
}

extension Emojis {
    enum Category: String, CaseIterable {
        case smileys = "Smileys & Emotion"
        case people = "People & Body"
        case nature = "Animals & Nature"
        case food = "Food & Drink"
        case travel = "Travel & Places"
        case activities = "Activities"
        case objects = "Objects"
        case symbols = "Symbols"
        case flags = "Flags"

        var title: String {
            switch self {
            case .smileys: R.string.localizable.emojiCategorySmileys()
            case .people: R.string.localizable.emojiCategoryPeople()
            case .nature: R.string.localizable.emojiCategoryNature()
            case .food: R.string.localizable.emojiCategoryFood()
            case .travel: R.string.localizable.emojiCategoryTravel()
            case .activities: R.string.localizable.emojiCategoryActivities()
            case .objects: R.string.localizable.emojiCategoryObjects()
            case .symbols: R.string.localizable.emojiCategorySymbols()
            case .flags: R.string.localizable.emojiCategoryFlags()
            }
        }
    }

    struct PickerSection: Identifiable {
        let category: Category
        let emojis: [String]
        var id: Category { category }
    }

    /// Preserve Smile's familiar order and keep aliases from creating duplicate buttons.
    private static let orderedSections: [PickerSection] = {
        let available = Set(all.values)
        var seen = Set<String>()
        return Category.allCases.map { category in
            let additions = newEmojis.sorted { $0.key < $1.key }
                .filter { $0.value.category == category }.map { $0.value.emoji }
            let ordered = ((Smile.emojiCategories[category.rawValue] ?? []) + additions)
                .filter { available.contains($0) && seen.insert($0).inserted }
            return PickerSection(category: category, emojis: ordered)
        }
    }()

    static func pickerSections(matching query: String) -> [PickerSection] {
        let search = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !search.isEmpty else { return orderedSections }
        let matches = Set(all.filter { name, symbol in
            name.replacingOccurrences(of: "_", with: " ").localizedCaseInsensitiveContains(search) || symbol.contains(search)
        }.values)
        return orderedSections.compactMap { section in
            let emojis = section.emojis.filter { matches.contains($0) }
            return emojis.isEmpty ? nil : PickerSection(category: section.category, emojis: emojis)
        }
    }
}
