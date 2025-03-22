//
//  Emojis.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 20.03.25.
//

import Smile

/// Adds support for emojis unavailable in Smile.
struct Emojis {
    // Emojis newer than our Smile version, we need to add them manually
    private static let newEmojis: [String: String] = [
        "melting_face": "🫠",
        "face_with_open_eyes_and_hand_over_mouth": "🫢",
        "face_with_peeking_eye": "🫣",
        "saluting_face": "🫡",
        "dotted_line_face": "🫥",
        "face_with_diagonal_mouth": "🫤",
        "face_holding_back_tears": "🥹",
        "rightwards_hand": "🫱",
        "palm_up_hand": "🫴",
        "hand_with_index_finger_and_thumb_crossed": "🫰",
        "index_pointing_at_the_viewer": "🫵",
        "heart_hands": "🫶",
        "biting_lip": "🫦",
        "person_with_crown": "🫅",
        "pregnant_man": "🫃",
        "pregnant_person": "🫄",
        // Unicode 15.0 Emojis: "🫨", "🫷", "🫸"
        "troll": "🧌",
        "coral": "🪸",
        "lotus": "🪷",
        "empty_nest": "🪹",
        "nest_with_eggs": "🪺",
        "beans": "🫘",
        // Unicode 15.0 Eat/Nature:"🕴", "🫎", "🫏", "🐿", "🪽", "🪿", "🪼", "🪻", "🫚", "🫛"
        "pouring_liquid": "🫗",
        "jar": "🫙",
        "mirror_ball": "🪩",
        "low_battery": "🪫",
        "crutch": "🩼",
        "x-ray": "🩻",
        "bubbles": "🫧",
        "identification_card": "🪪",
        "heavy_equals_sign": "🟰"
        // Unicode 15.0 Travel/Objects: "🛝", "🛞", "🛟", "🪭", "🪮", "🪇", "🪈", "🪬", "🩷", "🩵", "🩶", "⚠", "🪯", "🛜"
    ]

    static func getEmojiId(for emoji: String) -> String? {
        Smile.alias(emoji: emoji) ?? newEmojis.first(where: { $0.value == emoji })?.key
    }

    static func getEmoji(for id: String) -> String? {
        Smile.emoji(alias: id) ?? newEmojis[id]
    }
}
