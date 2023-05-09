//
//  File.swift
//  
//
//  Created by Sven Andabaka on 07.05.23.
//

import Foundation
import APIClient
import Common
import SharedModels
import UserStore

class NotificationWebsocketServiceImpl: NotificationWebsocketService {

    private let client = APIClient()

    private var continuation: AsyncStream<Notification>.Continuation?
    private var stream: AsyncStream<Notification>?

    private var subscribedTopics: [String] = []
    private var tasks: [Task<(), Never>] = []

    static let shared = NotificationWebsocketServiceImpl()

    let queue = DispatchQueue(label: "thread-safe")

    private init() { }

    /**
     * Subscribe to single user notification, group notification and quiz updates if it was not already subscribed.
     * Then it returns a  AsyncStream the calling component can listen on to actually receive the notifications.
     * @return AsyncStream<Notification>
     */
    func subscribeToNotifications() -> AsyncStream<Notification> {
        if let stream {
            return stream
        }

        let stream = AsyncStream<Notification> { continuation in
            continuation.onTermination = { [weak self] _ in
                self?.queue.async { [weak self] in
                    self?.tasks.forEach { $0.cancel() }
                    self?.continuation = nil
                    self?.subscribedTopics = []
                    self?.stream = nil
                }
            }

            self.continuation = continuation
        }

        self.stream = stream

        let subscribeToSingleUserNotificationUpdatesTask = Task {
            await subscribeToSingleUserNotificationUpdates()
        }
        addTask(subscribeToSingleUserNotificationUpdatesTask)
        let subscribeToCourseNotificationUpdatesTask = Task {
            await subscribeToCourseNotificationUpdates()
        }
        addTask(subscribeToCourseNotificationUpdatesTask)
        let subscribeToTutorialGroupNotificationUpdatesTask = Task {
            await subscribeToTutorialGroupNotificationUpdates()
        }
        addTask(subscribeToTutorialGroupNotificationUpdatesTask)
        let subscribeToConversationNotificationUpdatesTask = Task {
            await subscribeToConversationNotificationUpdates()
        }
        addTask(subscribeToConversationNotificationUpdatesTask)

        return stream
    }

    private func subscribeToSingleUserNotificationUpdates() async {
        guard let userId = UserSession.shared.user?.id else {
            log.debug("User could not be found. Subscribe to UserNotifications not possible")
            return
        }

        let topic = "/topic/user/\(userId)/notifications"
        let stream = subscribe(to: topic)

        let task = Task {
            for await message in stream {
                guard let notification = JSONDecoder.getTypeFromSocketMessage(type: Notification.self, message: message) else { continue }
                // Do not add notification to observer if it is a one-to-one conversation creation notification
                // and if the author is the current user
                // TODO: change title string here
                if notification.title != "artemisApp.singleUserNotification.title.createOneToOneChat" && userId != notification.author?.id {
                    continuation?.yield(notification)
                }
                guard let target = notification.target.toDictionary,
                      let message = target["message"] as? String else { continue }

                // subscribe to newly created conversation topic
                if message == "conversation-creation" {
                    if let conversationId = target["conversation"] {
                        let conversationTopic = "/topic/conversation/\(conversationId)/notifications"
                        await subscribeToNewlyCreatedConversation(conversationTopic: conversationTopic)
                    }
                }

                // unsubscribe from deleted conversation topic
                if message == "conversation-deletion" {
                    if let conversationId = target["conversation"] {
                        let conversationTopic = "/topic/conversation/\(conversationId)/notifications"
                        unsubscribeFromDeletedConversation(conversationTopic: conversationTopic)
                    }
                }
            }
        }
        addTask(task)
    }

    /**
     * Subscribe to newly created conversation topic (e.g. when user is added to a new conversation)
     */
    private func subscribeToNewlyCreatedConversation(conversationTopic: String) async {
        let stream = subscribe(to: conversationTopic)

        let task = Task {
            for await message in stream {
                guard let notification = JSONDecoder.getTypeFromSocketMessage(type: Notification.self, message: message) else { continue }
                continuation?.yield(notification)
            }
        }
        addTask(task)
    }

    /**
     * Unsubscribe from deleted conversation topic (e.g. when user deletes a conversation or when user is removed from conversation)
     */
    private func unsubscribeFromDeletedConversation(conversationTopic: String) {
        queue.async { [weak self] in
            ArtemisStompClient.shared.unsubscribe(from: conversationTopic)
            self?.subscribedTopics.removeAll(where: { $0 == conversationTopic })
        }
    }

    private func subscribeToCourseNotificationUpdates() async {
        let courses = await getCoursesForNotifications()
        switch courses {
        case .loading:
            return
        case .failure(let error):
            log.error("Could not subscribe to course notifications: \(error.localizedDescription)")
        case .done(let courses):
            await subscribeToGroupNotificationUpdates(courses: courses)
            await subscribeToQuizUpdates(courses: courses)
        }
    }

    private func subscribeToQuizUpdates(courses: [Course]) async {
        for course in courses {
            let quizExerciseTopic = "/topic/courses/\(course.id)/quizExercises"
            if !subscribedTopics.contains(quizExerciseTopic) {
                let stream = subscribe(to: quizExerciseTopic)
                let task = Task {
                    for await message in stream {
                        guard let quizExercise = JSONDecoder.getTypeFromSocketMessage(type: QuizExercise.self, message: message) else { continue }
                        if quizExercise.visibleToStudents ?? false,
                           quizExercise.quizMode == .SYNCHRONIZED,
                           quizExercise.quizBatches?.first?.started ?? false,
                           !(quizExercise.isOpenForPractice ?? false) {
                            let notification = Notification.createNotificationFromStartedQuizExercise(quizExercise: quizExercise)
                            continuation?.yield(notification)
                        }
                    }
                }
                addTask(task)
            }
        }
    }

    private func subscribeToGroupNotificationUpdates(courses: [Course]) async {
        for course in courses {
            var courseTopic = "/topic/course/\(course.id)/"
            if course.isAtLeastInstructorInCourse {
                courseTopic.append("INSTRUCTOR")
            } else if course.isAtLeastEditorInCourse {
                courseTopic.append("EDITOR")
            } else if course.isAtLeastTutorInCourse {
                courseTopic.append("TA")
            } else {
                courseTopic.append("STUDENT")
            }

            if !subscribedTopics.contains(courseTopic) {
                let stream = subscribe(to: courseTopic)
                let task = Task {
                    for await message in stream {
                        guard let notification = JSONDecoder.getTypeFromSocketMessage(type: Notification.self, message: message) else { continue }
                        continuation?.yield(notification)
                    }
                }
                addTask(task)
            }
        }
    }

    private func subscribeToTutorialGroupNotificationUpdates() async {
        let tutorialGroups = await getTutorialGroupsForNotifications()
        switch tutorialGroups {
        case .loading:
            return
        case .failure(let error):
            log.error("Could not subscribe to tutorial group notifications: \(error.localizedDescription)")
        case .done(let tutorialGroups):
            await subscribeToTutorialGroupNotificationUpdates(tutorialGroups: tutorialGroups)
        }
    }

    private func subscribeToTutorialGroupNotificationUpdates(tutorialGroups: [TutorialGroup]) async {
        for tutorialGroup in tutorialGroups {
            let tutorialGroupTopic = "/topic/tutorial-group/\(tutorialGroup.id)/notifications"
            if !subscribedTopics.contains(tutorialGroupTopic) {
                let stream = subscribe(to: tutorialGroupTopic)
                let task = Task {
                    for await message in stream {
                        guard let notification = JSONDecoder.getTypeFromSocketMessage(type: Notification.self, message: message) else { continue }
                        continuation?.yield(notification)
                    }
                }
                addTask(task)
            }
        }
    }

    private func subscribeToConversationNotificationUpdates() async {
        let conversations = await getConversationsForNotifications()
        switch conversations {
        case .loading:
            return
        case .failure(let error):
            log.error("Could not subscribe to conversations notifications: \(error.localizedDescription)")
        case .done(let conversations):
            subscribeToConversationNotificationUpdates(conversations: conversations)
        }
    }

    private func subscribeToConversationNotificationUpdates(conversations: [Conversation]) {
        for conversation in conversations {
            let conversationTopic = "/topic/conversation/\(conversation.id)/notifications"
            if !subscribedTopics.contains(conversationTopic) {
                let stream = subscribe(to: conversationTopic)
                let task = Task {
                    for await message in stream {
                        guard let notification = JSONDecoder.getTypeFromSocketMessage(type: Notification.self, message: message),
                              let userId = UserSession.shared.user?.id else { continue }

                        // Only add notification if it is not from the current user
                        if notification.author?.id != userId {
                            continuation?.yield(notification)
                        }
                    }
                }
                addTask(task)
            }
        }
    }

    private func subscribe(to topic: String) -> AsyncStream<Any?> {
        queue.async { [weak self] in
            self?.subscribedTopics.append(topic)
        }
        return ArtemisStompClient.shared.subscribe(to: topic)
    }

    private func addTask(_ task: Task<(), Never>) {
        queue.async { [weak self] in
            self?.tasks.append(task)
        }
    }
}

// needed API Endpoints to retrieve courses, group notifications, and course conversations
extension NotificationWebsocketServiceImpl {
    struct GetCoursesForNotificationsRequest: APIRequest {
        typealias Response = [Course]

        var method: HTTPMethod {
            return .get
        }

        var resourceName: String {
            return "api/courses/for-notifications"
        }
    }

    internal func getCoursesForNotifications() async -> DataState<[Course]> {
        let result = await client.sendRequest(GetCoursesForNotificationsRequest())

        switch result {
        case .success((let response, _)):
            return .done(response: response)
        case .failure(let error):
            return .failure(error: UserFacingError(error: error))
        }
    }

    struct GetTutorialGroupsForNotificationsRequest: APIRequest {
        typealias Response = [TutorialGroup]

        var method: HTTPMethod {
            return .get
        }

        var resourceName: String {
            return "api/tutorial-groups/for-notifications"
        }
    }

    internal func getTutorialGroupsForNotifications() async -> DataState<[TutorialGroup]> {
        let result = await client.sendRequest(GetTutorialGroupsForNotificationsRequest())

        switch result {
        case .success((let response, _)):
            return .done(response: response)
        case .failure(let error):
            return .failure(error: UserFacingError(error: error))
        }
    }

    struct GetConversationsForNotificationsRequest: APIRequest {
        typealias Response = [Conversation]

        var method: HTTPMethod {
            return .get
        }

        var resourceName: String {
            return "api/courses/conversations-for-notifications"
        }
    }

    internal func getConversationsForNotifications() async -> DataState<[Conversation]> {
        let result = await client.sendRequest(GetConversationsForNotificationsRequest())

        switch result {
        case .success((let response, _)):
            return .done(response: response)
        case .failure(let error):
            return .failure(error: UserFacingError(error: error))
        }
    }
}

private extension String {
    var toDictionary: [String: Any]? {
        let data = Data(self.utf8)
        do {
            // make sure this JSON is in the format we expect
            if let dictionary = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String: Any] {
                return dictionary
            }
        } catch {
            log.error(error)
        }
        return nil
    }
}

fileprivate extension Notification {
    static func createNotificationFromStartedQuizExercise(quizExercise: QuizExercise) -> Notification {
        Notification(id: Int.random(in: 0 ... Int.max),
                     title: "artemisApp.groupNotification.title.quizExerciseStarted",
                     text: "artemisApp.groupNotification.text.quizExerciseStarted",
                     notificationDate: .now,
                     target: "", // TODO: update target
//                     target: JSON.stringify({
//                         course: quizExercise.course!.id,
//                         mainPage: 'courses',
//                         entity: 'exercises',
//                         id: quizExercise.id,
//                     }),
                     author: nil,
                     notificationType: .group)
    }
}
