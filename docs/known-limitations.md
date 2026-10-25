# Known implementation limitations

- Swift modules remain in Swift 5 language mode while concurrency isolation is migrated; this warning cleanup does not claim Swift 6 migration.
- Native submission services cover modeling and text exercises. Other exercise types use the fallback service; native submission/result views remain unavailable. Removed commented-out view implementations were inactive and did not provide working support.
- Exercise cards currently show release and score-inclusion badges, without an active-quiz presentation badge.
- Thread deep links initially use a channel reference while navigation loads the full conversation.
- The current messages service exposes answer lookup through parent posts in a loaded page, and channel lookup through the conversation collection. Dedicated lookup APIs would avoid those collection requests.

These constraints remain visible here while source comments describe the current behavior without generating repeated build-time task reminders.
