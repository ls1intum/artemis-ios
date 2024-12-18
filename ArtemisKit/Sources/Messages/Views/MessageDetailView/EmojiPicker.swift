//
//  EmojiPicker.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 18.12.24.
//

import DesignLibrary
import Smile
import SwiftUI

struct EmojiPicker: View {
    @Environment(\.dismiss) var dismiss
    @State private var expanded = true

    var viewModel: ReactionsViewModel

    let columns = [
        GridItem(.adaptive(minimum: 60))
    ]

    var body: some View {
        let reactions = Array(viewModel.mappedReaction.keys) as [String]
        ScrollView {
            Group {
                DisclosureGroup(isExpanded: $expanded) {
                    emojiCategory(emojis: emojis, reactions: reactions)
                } label: {
                    Label("Emojis", systemImage: "smiley")
                }
                DisclosureGroup {
                    emojiCategory(emojis: animals, reactions: reactions)
                } label: {
                    Label("Animals & Nature", systemImage: "tree")
                }
                DisclosureGroup {
                    emojiCategory(emojis: fruit, reactions: reactions)
                } label: {
                    Label("Eat & Drink", systemImage: "takeoutbag.and.cup.and.straw")
                }
                DisclosureGroup {
                    emojiCategory(emojis: travel, reactions: reactions)
                } label: {
                    Label("Travel", systemImage: "airplane")
                }
                DisclosureGroup {
                    emojiCategory(emojis: objects, reactions: reactions)
                } label: {
                    Label("Objects", systemImage: "hourglass")
                }
                DisclosureGroup {
                    emojiCategory(emojis: symbols, reactions: reactions)
                } label: {
                    Label("Symbols", systemImage: "checkmark.circle.fill")
                }
            }
            .labelStyle(EmojiPickerLabelStyle())
            .padding(.horizontal, .l)
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(R.string.localizable.cancel()) {
                    dismiss()
                }
            }
        }
    }

    @ViewBuilder
    func emojiCategory(emojis: [String], reactions: [String]) -> some View {
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach(emojis, id: \.self) { emoji in
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.4))
                    .stroke(reactions.contains(emoji) && viewModel.isMyReaction(emoji) ? Color.blue : Color.clear,
                            style: StrokeStyle(lineWidth: 2))
                    .frame(width: 60, height: 60)
                    .overlay {
                        Text(emoji)
                            .font(.largeTitle)
                    }
                    .onTapGesture {
                        Task {
                            dismiss()
                            await viewModel.addReaction(emojiId: Smile.alias(emoji: emoji) ?? "")
                        }
                    }
            }
        }
    }

    // MARK: Emojis
    // Add new emojis here as needed. Smile doesn't include them properly at the moment.
    // https://util.unicode.org/UnicodeJsps/list-unicodeset.jsp?a=%5B%3AEmoji%3DYes%3A%5D&g=&i=

    // swiftlint:disable:next line_length
    let emojis = "😀 😃 😄 😁 😆 😅 🤣 😂 🙂 🙃 🫠 😉 😊 😇 🥰 😍 🤩 😘 😗 ☺ 😚 😙 🥲 😋 😛 😜 🤪 😝 🤑 🤗 🤭 🫢 🫣 🤫 🤔 🫡 🤐 🤨 😐 😑 😶 🫥 😏 😒 🙄 😬 🤥 🫨 😌 😔 😪 🤤 😴 😷 🤒 🤕 🤢 🤮 🤧 🥵 🥶 🥴 😵 🤯 🤠 🥳 🥸 😎 🤓 🧐 😕 🫤 😟 🙁 ☹ 😮 😯 😲 😳 🥺 🥹 😦 😨 😰 😥 😢 😭 😱 😖 😣 😞 😓 😩 😫 🥱 😤 😡 😠 🤬 😈 👿 💀 ☠ 💩 🤡 👹 👻 👽 👾 🤖 😺 😸 😹 😻 😽 🙀 😿 😾 🙈 🙉 🙊 👋 🤚 🖐 ✋ 🖖 🫱 🫴 🫷 🫸 👌 🤌 🤏 ✌ 🤞 🫰 🤟 🤘 🤙 👈 👉 👆 🖕 👇 ☝ 🫵 👍 👎 ✊ 👊 🤛 🤜 👏 🙌 🫶 👐 🤲 🤝 🙏 ✍ 💅 🤳 💪 🦾 🦿 🦵 🦶 👂 🦻 👃 🧠 🫀 🫁 🦷 🦴 👀 👁 👅 👄 🫦 👶 🧒 👦 👧 🧑 👱 👨 🧔 👩 🧓 👴 👵 🙍 🙎 🙅 🙆 💁 🙋 🧏 🙇 🤦 🤷 👮 🕵 💂 🥷 👷 🫅 🤴 👸 👳 👲 🧕 🤵 👰 🤰 🫃 🫄 🤱 👼 🎅 🤶 🦸 🦹 🧙 🧟 🧌 💆 💇 🚶 🧍 🧎 🏃 💃 🕺 🕴 👯 🧖 🧗 🤺 🏇 ⛷ 🏂 🏌 🏄 🚣 🏊 ⛹ 🏋 🚴 🚵 🤸 🤼 🤾 🤹 🧘 🛀 🛌 👭 👫 👬 💏 💑 🗣 👤 👥 🫂 👪 👣 🦰 🦱 🦳 🦲".split(separator: " ").map { String($0) }
    // swiftlint:disable:next line_length
    let animals = "🐵 🐒 🦍 🦧 🐶 🐕 🦮 🐩 🐺 🦊 🦝 🐱 🐈 🦁 🐯 🐅 🐆 🐴 🫎 🫏 🐎 🦄 🦓 🦌 🦬 🐮 🐂 🐄 🐷 🐖 🐗 🐽 🐏 🐑 🐐 🐪 🐫 🦙 🦒 🐘 🦣 🦏 🦛 🐭 🐁 🐀 🐹 🐰 🐇 🐿 🦫 🦔 🦇 🐻 🐨 🐼 🦥 🦦 🦨 🦘 🦡 🐾 🦃 🐔 🐓 🐣 🐧 🕊 🦅 🦆 🦢 🦉 🦤 🪶 🦩 🦚 🦜 🪽 🪿 🐸 🐊 🐢 🦎 🐍 🐲 🐉 🦕 🦖 🐳 🐋 🐬 🦭 🐟 🐡 🦈 🐙 🐚 🪸 🪼 🐌 🦋 🐛 🐝 🪲 🐞 🦗 🪳 🕷 🕸 🦂 🦟 🪰 🪱 🦠 💐 🌸 💮 🪷 🏵 🌹 🥀 🌺 🌼 🌷 🪻 🌱 🪴 🌲 🌵 🌾 🌿 ☘ 🍀 🍃 🪹 🪺 🍄 🍇 🍍 🥭".split(separator: " ").map { String($0) }
    // swiftlint:disable:next line_length
    let fruit = "🍎 🍓 🫐 🥝 🍅 🫒 🥥 🥑 🍆 🥔 🥕 🌽 🌶 🫑 🥒 🥬 🥦 🧄 🧅 🥜 🫘 🌰 🫚 🫛 🍞 🥐 🥖 🫓 🥨 🥯 🥞 🧇 🧀 🍖 🍗 🥩 🥓 🍔 🍟 🍕 🌭 🥪 🌮 🌯 🫔 🥙 🧆 🥚 🍳 🥘 🍲 🫕 🥣 🥗 🍿 🧈 🧂 🥫 🍱 🍘 🍝 🍠 🍢 🍥 🥮 🍡 🥟 🥡 🦀 🦞 🦐 🦑 🦪 🍦 🍪 🎂 🍰 🧁 🥧 🍫 🍯 🍼 🥛 ☕ 🫖 🍵 🍶 🍾 🍷 🍻 🥂 🥃 🫗 🥤 🧋 🧃 🧉 🧊 🥢 🍽 🍴 🥄 🔪 🫙".split(separator: " ").map { String($0) }
    // swiftlint:disable:next line_length
    let travel = "🌍 🌐 🗺 🗾 🧭 🏔 ⛰ 🌋 🗻 🏕 🏖 🏜 🏟 🏛 🏗 🧱 🪨 🪵 🛖 🏘 🏚 🏠 🏦 🏨 🏭 🏯 🏰 💒 🗼 🗽 ⛪ 🕌 🛕 🕍 ⛩ 🕋 ⛲ ⛺ 🌁 🌃 🏙 🌄 🌇 🌉 ♨ 🎠 🛝 🎡 🎢 💈 🎪 🚂 🚊 🚝 🚞 🚋 🚎 🚐 🚙 🛻 🚚 🚜 🏎 🏍 🛵 🦽 🦼 🛺 🚲 🛴 🛹 🛼 🚏 🛣 🛤 🛢 ⛽ 🛞 🚨 🚥 🚦 🛑 🚧 ⚓ 🛟 ⛵ 🛶 🚤 🛳 ⛴ 🛥 🚢 ✈ 🛩 🛫 🛬 🪂 💺 🚁 🚟 🚡 🛰 🚀 🛸".split(separator: " ").map { String($0) }
    // swiftlint:disable:next line_length
    let objects = "🛎 🧳 ⌛ ⏳ ⌚ ⏰ ⏲ 🕰 🕛 🕧 🕐 🕜 🕑 🕝 🕒 🕞 🕓 🕟 🕔 🕠 🕕 🕡 🕖 🕢 🕗 🕣 🕘 🕤 🕙 🕥 🕚 🕦 🌑 🌜 🌡 ☀ 🌝 🌞 🪐 ⭐ 🌟 🌠 🌌 ☁ ⛅ ⛈ 🌤 🌬 🌀 🌈 🌂 ☂ ☔ ⛱ ⚡ ❄ ☃ ⛄ ☄ 🔥 💧 🌊 🎃 🎄 🎆 🎇 🧨 ✨ 🎈 🎋 🎍 🎑 🧧 🎀 🎁 🎗 🎟 🎫 🎖 🏆 🏅 🥇 🥉 ⚽ ⚾ 🥎 🏀 🏐 🏈 🏉 🎾 🥏 🎳 🏏 🏑 🏒 🥍 🏓 🏸 🥊 🥋 🥅 ⛳ ⛸ 🎣 🤿 🎽 🎿 🛷 🥌 🎯 🪀 🪁 🔫 🎱 🔮 🪄 🎮 🕹 🎰 🎲 🧩 🧸 🪅 🪩 🪆 ♠ ♥ ♦ ♣ ♟ 🃏 🀄 🎴 🎭 🖼 🎨 🧵 🪡 🧶 🪢 👓 🕶 🥽 🥼 🦺 👔 👖 🧣 🧦 👗 👘 🥻 🩱 🩳 👙 👚 🪭 👛 👝 🛍 🎒 🩴 👞 👟 🥾 🥿 👠 👡 🩰 👢 🪮 👑 👒 🎩 🎓 🧢 🪖 ⛑ 📿 💄 💍 💎 🔇 🔊 📢 📣 📯 🔔 🔕 🎼 🎵 🎶 🎙 🎛 🎤 🎧 📻 🎷 🪗 🎸 🎻 🪕 🥁 🪘 🪇 🪈 📱 📲 ☎ 📞 📠 🔋 🪫 🔌 💻 🖥 🖨 ⌨ 🖱 🖲 💽 📀 🧮 🎥 🎞 📽 🎬 📺 📷 📹 📼 🔍 🔎 🕯 💡 🔦 🏮 🪔 📔 📚 📓 📒 📃 📜 📄 📰 🗞 📑 🔖 🏷 💰 🪙 💴 💸 💳 🧾 💹 ✉ 📧 📩 📤 📦 📫 📪 📬 📮 🗳 ✏ ✒ 🖋 🖊 🖌 🖍 📝 💼 📁 📂 🗂 📅 📆 🗒 🗓 📇 📎 🖇 📏 📐 ✂ 🗃 🗄 🗑 🔒 🔓 🔏 🔑 🗝 🔨 🪓 ⛏ ⚒ 🛠 🗡 ⚔ 💣 🪃 🏹 🛡 🪚 🔧 🪛 🔩 ⚙ 🗜 ⚖ 🦯 🔗 ⛓ 🪝 🧰 🧲 🪜 ⚗ 🧪 🧬 🔬 🔭 📡 💉 🩸 💊 🩹 🩼 🩺 🩻 🚪 🛗 🪞 🪟 🛏 🛋 🪑 🚽 🪠 🚿 🛁 🪤 🪒 🧴 🧷 🧹 🧻 🪣 🧼 🫧 🪥 🧽 🧯 🛒 🚬 ⚰ 🪦 ⚱ 🧿 🪬 🗿 🪧 🪪".split(separator: " ").map { String($0) }
    // swiftlint:disable:next line_length
    let symbols = "💌 💘 💝 💖 💗 💓 💞 💕 💟 ❣ 💔 ❤ 🩷 🧡 💛 💚 💙 🩵 💜 🤎 🖤 🩶 🤍 💋 💯 💢 💥 💫 💦 💨 🕳 💬 🗨 🗯 💭 💤 🏧 🚮 🚰 ♿ 🚹 🚼 🚾 🛂 🛅 ⚠ 🚸 ⛔ 🚫 🚳 🚭 🚯 🚱 🚷 📵 🔞 ☢ ☣ ⬆ ↗ ➡ ↘ ⬇ ↙ ⬅ ↖ ↕ ↔ ↩ ↪ ⤴ ⤵ 🔃 🔄 🔙 🔝 🛐 ⚛ 🕉 ✡ ☸ ☯ ✝ ☦ ☪ ☮ 🕎 🔯 🪯 ♈ ♓ ⛎ 🔀 🔂 ▶ ⏩ ⏭ ⏯ ◀ ⏪ ⏮ 🔼 ⏫ 🔽 ⏬ ⏸ ⏺ ⏏ 🎦 🔅 🔆 📶 🛜 📳 📴 ♀ ♂ ⚧ ✖ ➕ ➗ 🟰 ♾ ‼ ⁉ ❓ ❕ ❗ 〰 💱 💲 ⚕ ♻ ⚜ 🔱 📛 🔰 ⭕ ✅ ☑ ✔ ❌ ❎ ➰ ➿ 〽 ✳ ✴ ❇ © ® ™ 🔟 🔤 🅰 🆎 🅱 🆑 🆓 ℹ 🆔 Ⓜ 🆕 🆖 🅾 🆗 🅿 🆘 🆚 🈁 🈂 🈷 🈶 🈯 🉐 🈹 🈚 🈲 🉑 🈸 🈴 🈳 ㊗ ㊙ 🈺 🈵 🔴 🟠 🟢 🔵 🟣 🟤 ⚫ ⚪ 🟥 🟧 🟩 🟦 🟪 🟫 ⬛ ⬜ ◼ ◻ ◾ ◽ ▪ ▫ 🔶 🔻 💠 🔘 🔳 🔲 🏁 🚩 🎌 🏴 🏳".split(separator: " ").map { String($0) }
}

private struct EmojiPickerLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.icon.frame(width: 30)
            configuration.title
        }
        .font(.title2.weight(.semibold))
        .padding(.vertical, .m)
        .foregroundStyle(.primary)
    }
}
