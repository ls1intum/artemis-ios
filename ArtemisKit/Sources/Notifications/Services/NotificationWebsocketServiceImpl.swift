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

    let queue = DispatchQueue(label: "thread-safe-websocket-notification")

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
#warning("We can't subscribe to this here and in the conversation simultaneously")
//        let subscribeToConversationNotificationUpdatesTask = Task {
//            await subscribeToConversationNotificationUpdates()
//        }
//        addTask(subscribeToConversationNotificationUpdatesTask)

        return stream
    }

    private func subscribeToSingleUserNotificationUpdates() async {
        guard let userId = UserSessionFactory.shared.user?.id else {
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
            if !contains(topic: quizExerciseTopic) {
                let stream = subscribe(to: quizExerciseTopic)
                let task = Task {
                    for await message in stream {
                        guard let quizExercise = JSONDecoder.getTypeFromSocketMessage(type: QuizExercise.self, message: message) else { continue }
                        if quizExercise.visibleToStudents ?? false,
                           quizExercise.quizMode == .synchronized,
                           quizExercise.quizBatches?.first?.started ?? false,
                           !(quizExercise.isOpenForPractice ?? false) {
                            guard let notification = Notification.createNotificationFromStartedQuizExercise(quizExercise: quizExercise) else { continue }
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

            if !contains(topic: courseTopic) {
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
        guard let userId = UserSessionFactory.shared.user?.id else {
            log.debug("User could not be found. Subscription to UserNotifications is not possible")
            return
        }

        let topic = "/topic/user/\(userId)/notifications/tutorial-groups"
        let stream = subscribe(to: topic)

        let task = Task {
            for await message in stream {
                guard let notification = JSONDecoder.getTypeFromSocketMessage(type: Notification.self, message: message) else { continue }
                continuation?.yield(notification)
            }
        }
        addTask(task)
    }

    private func subscribeToConversationNotificationUpdates() async {
        guard let userId = UserSessionFactory.shared.user?.id else {
            log.debug("User could not be found. Subscription to UserNotifications is not possible")
            return
        }

        let topic = "/topic/user/\(userId)/notifications/conversations"
        let stream = subscribe(to: topic)

        let task = Task {
            for await message in stream {
                guard let notification = JSONDecoder.getTypeFromSocketMessage(type: Notification.self, message: message),
                      let userId = UserSessionFactory.shared.user?.id else { continue }

                // Only add notification if it is not from the current user
                if notification.author?.id != userId {
                    continuation?.yield(notification)
                }
            }
        }
        addTask(task)
    }

    private func contains(topic: String) -> Bool {
        var doesContain: Bool?
        queue.sync { [weak self] in
            doesContain = self?.subscribedTopics.contains(topic)
        }
        return doesContain ?? false
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
    static func createNotificationFromStartedQuizExercise(quizExercise: QuizExercise) -> Notification? {
        guard let course = quizExercise.course,
              let quizTitle = quizExercise.title,
              let notificationTarget = try? JSONEncoder().encode(QuizExerciseTarget(course: course.id,
                                                                                    id: quizExercise.id)) else {
            return nil
        }

        return Notification(id: Int.random(in: 0 ... Int.max),
                            title: "artemisApp.groupNotification.title.quizExerciseStarted",
                            text: nil,
                            notificationDate: .now,
                            target: String(decoding: notificationTarget, as: UTF8.self),
                            author: nil,
                            placeholderValues: "[\(course.title),\(quizTitle)]")
    }

    struct QuizExerciseTarget: Codable {
        let course: Int
        var mainPage = "courses"
        var entity = "exercises"
        let id: Int
    }
}
