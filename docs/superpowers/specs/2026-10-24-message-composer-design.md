# Communication composer

The requested Slack iOS interaction is the design authority for this scoped replacement. Preserve Artemis's native selection, undo, drafts, attachments, course references, and Markdown protocol.

## Experience

- One rounded system-glass container, with full-width text above one always-visible toolbar. Use a solid system surface with Reduce Transparency.
- Show the conversation or reply placeholder in secondary text. Grow naturally as text wraps, then scroll inside a bounded editor; remove fullscreen and resizing state entirely.
- Default row: attachment/add menu, Aa, emoji, @, #, and a fixed circular send control. The add menu preserves exercise, lecture and FAQ references.
- Aa replaces the middle of the same row with horizontally scrolling direct formatting actions. A fixed close control restores the default row; send remains visible. All targets are at least 44 points, with names and selected states for accessibility.
- Keep Send disabled for whitespace and empty formatting; allow an empty optional forwarding comment.
- Keep native keyboard focus and selection through formatting actions. Emoji selection inserts at the saved caret. Keep uploads and picker presentation owned by the composer.
- Quotes render as indented text with a vertical rule, without visible Markdown punctuation. Preserve inline styles and quote Markdown through paste, copy, undo and reopening.
- Continue bullet and numbered lists on every Return. Return on an empty item exits the list. Test with actual native editing across SwiftUI updates.

## Approach

Restyling the existing stacked toolbar would retain its extra height and discovery problems. Replacing the editing engine would risk draft and serialization regressions. Keep the existing UITextView/document bridge and replace only the composer shell and toolbar, fixing structural editing at its source.

## Validation

Run native iOS Simulator package tests and the unsigned app build; inspect light/dark, narrow/wide, long-text, formatting, and accessibility-size captures. The installed runtime supports iPhone Duo only; report that device-coverage limit. No new dependencies.
