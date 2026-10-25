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

## Drag resizing and transparent emoji headings

- [x] Add regressions for bounded drag tracking, snapping, interruption and compact-window recovery, plus native editor growth within a height budget.
- [x] Add the accessible grabber and bounded extra editor height; preserve keyboard focus, selection, and reachable controls. Remove the emoji header backing and pinned behavior, using quieter typography.
- [x] Run the package suite on iPhone/iPad, inspect native interaction captures, obtain code review, restore app/test entry points, build/lint, and save screencasts before committing and pushing.

Drag-resize validation (2026-10-25): 194 package tests pass on each simulator. A parent-layout regression reproduced the message list stealing composer height; the whole composer now has layout priority ahead of sibling scroll views. Native drag up/down, tap fallback, continued typing, emoji search/insertion, and portrait/landscape reachability pass on iPhone 17 Pro and iPad Pro 11-inch (M4), iOS/iPadOS 26.2. Light/dark native captures confirm transparent category headers. Both 27-second H.264 screencasts decode fully. App/test entry points are restored; unsigned production build, strict SwiftLint on six changed Swift files and diff checks pass. The iPad capture passed after a Simulator restart resolved a SpringBoard automation wait.

## Full PR correctness audit (2026-10-25)

- [x] Reproduce and fix quote-prefix loss when inserting emoji, completion triggers, or links from the toolbar.
- [x] Preserve reference payloads and literal private-use scalars beside combining accents and variation selectors, including decode, CommonMark fallback, encode, and reopening. Disambiguate file labels matching Artemis reference tags from following references.
- [x] Preserve newly edited identical conversation/reply drafts when another composer finishes sending from a separate repository context.
- [x] Reset native undo and unfinished IME composition when replacing the editor document; retain both for ordinary updates to the same document.
- [x] Handle missing, invalid, or failed image transfers; expose cancellation while loading/compressing; discard cancelled and superseded results. Isolate upload state on MainActor and perform image decoding/JPEG compression outside it.
- [x] Isolate hosted completion tests with in-memory storage and injected service stubs. Verify file/image attachments yield to the editor and toolbar in compact and regular height constraints. Expose the selected Link accessibility trait and correct the README's composer description.

Red runs reproduced the data-loss and stalled-upload defects before their fixes. Final package verification passes **221 tests with zero failures on each of iPhone 17 Pro and iPad Pro 11-inch (M4), iOS/iPadOS 26.2**. The unsigned production Simulator app builds successfully. Strict SwiftLint 0.55.1 passes for **all 47 changed Swift files** without cache; diff checks pass. Independent reviews found no remaining actionable defect. The original app and UI-test entry points are unchanged by this audit.

The previous GitHub Actions package test job passed. Its signed build failed before compilation because Fastlane could not authenticate to the GitLab certificates repository (`IOS_MATCH_GITLAB_AUTH`); no signing checks are bypassed.
