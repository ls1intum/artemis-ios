import Foundation
import SharedModels
import PushNotifications
import Common

struct Notification: Codable {
    var id: Int
    let title: String
    let notificationDate: Date
    let target: String
    let author: NotificationUser?
    let placeholderValues: String?
}

// we can't just use User.swift here because the authorities are having a different type (dictionary instead array) in notifications
struct NotificationUser: UserPublicInfo {
    var id: Int64
    var login: String?
    var name: String?
    var firstName: String?
    var lastName: String?
    var isInstructor: Bool?
    var isEditor: Bool?
    var isTeachingAssistant: Bool?
    var isStudent: Bool?
}

extension Notification: Identifiable { }

extension Notification {

    var pushNotificationType: PushNotificationType? {
        switch title {
        case "artemisApp.singleUserNotification.title.exerciseSubmissionAssessed":
            return .exerciseSubmissionAssessed
        case "artemisApp.groupNotification.title.attachmentChange":
            return .attachmentChange
        case "artemisApp.groupNotification.title.exerciseReleased":
            return .exerciseReleased
        case "artemisApp.groupNotification.title.exercisePractice":
            return .exercisePractice
        case "artemisApp.groupNotification.title.quizExerciseStarted":
            return .quizExerciseStarted
        case "artemisApp.groupNotification.title.newReplyForExercisePost":
            return .newReplyForExercisePost
        case "artemisApp.groupNotification.title.newReplyForLecturePost":
            return .newReplyForLecturePost
        case "artemisApp.groupNotification.title.newReplyForCoursePost":
            return .newReplyForCoursePost
        case "artemisApp.groupNotification.title.newExercisePost":
            return .newExercisePost
        case "artemisApp.groupNotification.title.newLecturePost":
            return .newLecturePost
        case "artemisApp.groupNotification.title.newCoursePost":
            return .newCoursePost
        case "artemisApp.groupNotification.title.newAnnouncementPost":
            return .newAnnouncementPost
        case "artemisApp.singleUserNotification.title.fileSubmissionSuccessful":
            return .fileSubmissionSuccessful
        case "artemisApp.groupNotification.title.duplicateTestCase":
            return .duplicateTestCase
        case "artemisApp.singleUserNotification.title.newPlagiarismCaseStudent":
            return .newPlagiarismCaseStudent
        case "artemisApp.singleUserNotification.title.plagiarismCaseVerdictStudent":
            return .newPlagiarismCaseStudent
        case "artemisApp.conversationNotification.title.newMessage":
            return .conversationNewMessage
        case "artemisApp.singleUserNotification.title.messageReply":
            return .conversationNewReplyMessage
        // TODO: add handling for non push notification types
        default:
            return nil
        }
    }

    var encodedTitle: String? {
        pushNotificationType?.title
    }

    var encodedBody: String? {
        guard let placeholderValues else { return nil }
        if let jsonData = placeholderValues.data(using: .utf8) {
            let decoder = JSONDecoder()
            do {
                let array = try decoder.decode([String].self, from: jsonData)
                return pushNotificationType?.getBody(notificationPlaceholders: array)
            } catch {
                log.error(error)
                return nil
            }
        }
        return nil
    }
}
