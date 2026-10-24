# Communication composer implementation plan

> Execute inline using superpowers:executing-plans. The user supplied the interaction design and requested implementation on PR #554.

**Goal:** Match the supplied Slack iOS composer interaction while retaining Artemis content and persistence.

**Architecture:** Keep the native attributed document and Markdown codec. Replace the SwiftUI shell/toolbar and remove fullscreen state; repair native block editing and render quotes in TextKit.

**Tech stack:** SwiftUI, UIKit/TextKit, XCTest, iOS 26+.

## Review follow-up

- [x] Reproduce completion overflow in a 170-point-high host for users and channels in both size classes. Let suggestions shrink before the editor and toolbar; rerun presentation tests.
- [x] Keep the existing emoji button. Add ordered, localized sections using Smile's existing categories, categorize newer emojis, and test complete coverage, deduplication and search.
- [x] Enable interactive keyboard dismissal on conversation, thread and forwarding scroll views, including empty conversations. Verify the gestures and completion selection on iPhone and iPad simulators, then run package tests, build, lint and review before committing and pushing to PR #554.

**Spec:** ../specs/2026-10-24-message-composer-design.md

## Tasks

- [x] Reproduce repeated list Return with native typing, including SwiftUI redraws, empty-item exit and numbered rollover. Fix the underlying attribute/selection handling and retain undo.
- [x] Add quote-preview regression tests. Use an invisible structural quote prefix, paragraph indentation and a TextKit rule; encode `> ` only at the Markdown boundary. Check paste, backspace, toggling, copying and reopening.
- [x] Replace SendMessageView/SendMessageKeyboardToolbar with a single-row composer and a bounded auto-growing transparent MessageRichTextEditor. Remove editorExpanded; retain native focus and picker ownership. Add emoji insertion and localized action names; use failable UTF-8 paste decoding.
- [x] Replace old fullscreen/two-row presentation assertions with full-width, fixed-height toolbar, long-draft, compact-height and larger-text checks. Run the full native test suite, unsigned app build, SwiftLint and diff checks. Inspect captures and obtain a fresh read-only review.

## Review focus

Native attribute normalization after intercepted Return; structural prefix edits and undo; focus/selection when controls replace each other; upload sheets while unfocused; toolbar/send visibility in narrow and keyboard-constrained layouts.

## Verification record

- Initial native regressions reproduced missing UIKeyInput list continuation and visible quote markers. The final package suite passes **183 tests, zero failures**.
- Fresh code review identified quote-start mention completion and insertion before the invisible prefix. Covered by quote-boundary tests and fixed. Prefix deletion also restores a plain paragraph.
- Native UI automation in a temporary host passed Aa open/close, three software-keyboard numbered items, fixed send visibility, the image/file menu, emoji search and insertion. Separate native capture confirmed accessibility-extra-large body text with reachable controls. Temporary app/test entry points are restored before final validation.
- The final layout/empty-message tests reproduced and fixed a non-shrinkable minimum-height probe and sending whitespace or empty formatting. Forwarded messages still allow an empty optional comment.
- SwiftLint on all 16 changed Swift files: no warnings or errors. `git diff --check` passes.
- Visual review confirmed the requested composition, quote preview and native materials. Its light-placeholder contrast finding is addressed with adaptive primary gray at 60% opacity; the follow-up visual review measured approximately **5.69:1** contrast and scored the fix resolved. The final unsigned production app build succeeds with original app/test entry points restored.

Native captures and logs are local under `/tmp/artemis-ios-composer-review` and `/tmp/artemis-ios-composer-*.log`. The installed iOS 27.1 runtime supports iPhone Duo only; unit hosting covers narrow/wide sizes, while physical-device, tablet, VoiceOver and live-upload checks remain outside this run.

Follow-up validation: 186 package tests pass on both iPhone 17 Pro and iPad Pro 11-inch (M4), iOS/iPadOS 26.2. Native populated-completion, portrait/landscape, keyboard-dismissal and emoji-search/insertion checks pass. The restored production app builds; SwiftLint passes for all eight changed Swift files. Independent review found no actionable issues. Five updated native screenshots are saved in the Desktop review folder.
