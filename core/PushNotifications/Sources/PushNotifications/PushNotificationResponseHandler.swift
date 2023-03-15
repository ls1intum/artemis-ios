//
//  File.swift
//  
//
//  Created by Sven Andabaka on 12.03.23.
//

import Foundation

public class PushNotificationResponseHandler {

    // TODO: implement for other types
    public static func getTarget(userInfo: [AnyHashable: Any]) -> String? {
        guard let targetString = userInfo[PushNotificationUserInfoKeys.target] as? String,
              let typeString = userInfo[PushNotificationUserInfoKeys.type] as? String else {
            return nil
        }

        let decoder = JSONDecoder()
        let targetData = Data(targetString.utf8)
        guard let type = PushNotificationType(rawValue: typeString) else { return nil }

        switch type {
//        case .exerciseSubmissionAssessed:
//            <#code#>
//        case .attachmentChange:
//            <#code#>
//        case .exerciseReleased:
//            <#code#>
//        case .exercisePractice:
//            <#code#>
//        case .quizExerciseStarted:
//            <#code#>
//        case .newReplyForLecturePost:
//            <#code#>
        case .newReplyForCoursePost:
            guard let target = try? decoder.decode(NewReplyForCoursePostTarget.self, from: targetData) else { return nil }
            return "courses/\(target.course)/discussion?searchText=%23\(target.id)"
//        case .newExercisePost:
//
//        case .newLecturePost:
//            <#code#>
//        case .newCoursePost:
//            <#code#>
//        case .newAnnouncementPost:
//            <#code#>
//        case .fileSubmissionSuccessful:
//            <#code#>
//        case .duplicateTestCase:
//            <#code#>
//        case .newPlagiarismCaseStudent:
//            <#code#>
//        case .plagiarismCaseVerdictStudent:
//            <#code#>
        default:
            return nil
        }
    }
}

private struct NewReplyForCoursePostTarget: Codable {
    let course: Int
    let id: Int
}
