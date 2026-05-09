//
//  IrisErrors.swift
//  ArtemisKit
//
//  Created by Senan Aslan on 09.05.26.
//

/// All known Iris error categories. Raw values match the i18n keys used by
/// the webapp (`iris-errors.model.ts`); iOS may render them via its own
/// `Localizable.strings` but the identifiers stay aligned for cross-checks.
///
/// Use `isFatal` to decide whether the chat is unusable and a session reset
/// is required (e.g. Pyris down, rate limit hit, AI declined).
enum IrisErrorMessageKey: String, CaseIterable {
    case sessionLoadFailed = "artemisApp.exerciseChatbot.errors.sessionLoadFailed"
    case sendMessageFailed = "artemisApp.exerciseChatbot.errors.sendMessageFailed"
    case historyLoadFailed = "artemisApp.exerciseChatbot.errors.historyLoadFailed"
    case invalidSessionState = "artemisApp.exerciseChatbot.errors.invalidSessionState"
    case sessionCreationFailed = "artemisApp.exerciseChatbot.errors.sessionCreationFailed"
    case rateMessageFailed = "artemisApp.exerciseChatbot.errors.rateMessageFailed"
    case irisDisabled = "artemisApp.exerciseChatbot.errors.irisDisabled"
    case irisServerResponseTimeout = "artemisApp.exerciseChatbot.errors.timeout"
    case emptyMessage = "artemisApp.exerciseChatbot.errors.emptyMessage"
    case forbidden = "artemisApp.exerciseChatbot.errors.forbidden"
    case internalPyrisError = "artemisApp.exerciseChatbot.errors.internalPyrisError"
    case invalidTemplate = "artemisApp.exerciseChatbot.errors.invalidTemplate"
    case noModelAvailable = "artemisApp.exerciseChatbot.errors.noModelAvailable"
    case noResponse = "artemisApp.exerciseChatbot.errors.noResponse"
    case parseResponse = "artemisApp.exerciseChatbot.errors.parseResponse"
    case technicalErrorResponse = "artemisApp.exerciseChatbot.errors.technicalError"
    case irisNotAvailable = "artemisApp.exerciseChatbot.errors.irisNotAvailable"
    case rateLimitExceeded = "artemisApp.exerciseChatbot.errors.rateLimitExceeded"
    case aiUsageDeclined = "artemisApp.exerciseChatbot.errors.aiUsageDeclined"

    /// `true` if encountering this error renders the chat unusable until a
    /// reset (matches the `fatal: true` entries in `iris-errors.model.ts`).
    var isFatal: Bool {
        switch self {
        case .sendMessageFailed,
             .rateMessageFailed,
             .irisServerResponseTimeout,
             .emptyMessage:
            return false
        case .sessionLoadFailed,
             .historyLoadFailed,
             .invalidSessionState,
             .sessionCreationFailed,
             .irisDisabled,
             .forbidden,
             .internalPyrisError,
             .invalidTemplate,
             .noModelAvailable,
             .noResponse,
             .parseResponse,
             .technicalErrorResponse,
             .irisNotAvailable,
             .rateLimitExceeded,
             .aiUsageDeclined:
            return true
        }
    }
}
