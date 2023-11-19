import Foundation
import SharedModels
import PushNotifications
import Common

struct Notification: Codable {
    var id: Int
    let title: String
    let text: String?
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
        case "artemisApp.groupNotification.title.exerciseUpdated":
            return .exerciseUpdated
        case "artemisApp.groupNotification.title.courseArchiveStarted":
            return .courseArchiveStarted
        case "artemisApp.groupNotification.title.courseArchiveFinished":
            guard let text else {
                return .courseArchiveFinished
            }
            switch text {
            case "artemisApp.groupNotification.text.courseArchiveFinishedWithErrors":
                return .courseArchiveFinishedWithError
            case "artemisApp.groupNotification.text.courseArchiveFinishedWithoutErrors":
                return .courseArchiveFinishedWithoutError
            default:
                return nil
            }
        case "artemisApp.groupNotification.title.courseArchiveFailed":
            return .courseArchiveFailed
        case "artemisApp.groupNotification.title.examArchiveStarted":
            return .examArchiveStarted
        case "artemisApp.groupNotification.title.examArchiveFinished":
            guard let text else {
                return .examArchiveFinished
            }
            switch text {
            case "artemisApp.groupNotification.text.examArchiveFinishedWithErrors":
                return .examArchiveFinishedWithError
            case "artemisApp.groupNotification.text.examArchiveFinishedWithoutErrors":
                return .examArchiveFinishedWithoutError
            default:
                return nil
            }
        case "artemisApp.groupNotification.title.examArchiveFailed":
            return .examArchiveFailed
        case "artemisApp.groupNotification.title.illegalSubmission":
            return .illegalSubmission
        case "artemisApp.groupNotification.title.programmingTestCasesChanged":
            return .programmingTestCasesChanged
        case "artemisApp.groupNotification.title.newManualFeedbackRequest":
            return .newManualFeedbackRequest
        case "artemisApp.singleUserNotification.title.tutorialGroupRegistrationStudent":
            return .tutorialGroupDegregistrationStudent
        case "artemisApp.singleUserNotification.title.tutorialGroupDeregistrationStudent":
            return .tutorialGroupDegregistrationStudent
        case "artemisApp.singleUserNotification.title.tutorialGroupRegistrationTutor":
            return .tutorialGroupRegistrationTutor
        case "artemisApp.singleUserNotification.title.tutorialGroupDeregistrationTutor":
            return .tutorialGroupDeregistrationTutor
        case "artemisApp.singleUserNotification.title.tutorialGroupMultipleRegistrationTutor":
            return .tutorialGroupMultipleRegistrationTutor
        case "artemisApp.singleUserNotification.title.tutorialGroupAssigned":
            return .tutorialGroupAssigned
        case "artemisApp.singleUserNotification.title.tutorialGroupUnassigned":
            return .tutorialGroupUnassigned
        case "artemisApp.tutorialGroupNotification.title.tutorialGroupDeleted":
            return .tutorialGroupDeleted
        case "artemisApp.tutorialGroupNotification.title.tutorialGroupUpdated":
            return .tutorialGroupUpdated
        case "artemisApp.singleUserNotification.title.deleteChannel":
            return .conversationDeleteChannel
        case "artemisApp.singleUserNotification.title.removeUserChannel":
            return .conversationRemoveUserChannel
        case "artemisApp.singleUserNotification.title.addUserChannel":
            return .conversationAddUserChannel
        case "artemisApp.singleUserNotification.title.removeUserGroupChat":
            return .conversationRemoveUserGroupChat
        case "artemisApp.singleUserNotification.title.addUserGroupChat":
            return .conversationAddUserGroupChat
        case "artemisApp.singleUserNotification.title.createGroupChat":
            return .conversationCreateGroupChat
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
