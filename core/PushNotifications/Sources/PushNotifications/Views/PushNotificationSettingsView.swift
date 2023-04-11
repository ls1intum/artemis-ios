//
//  PushNotificationSettingsView.swift
//  
//
//  Created by Sven Andabaka on 28.03.23.
//

import SwiftUI
import DesignLibrary

public struct PushNotificationSettingsView: View {

    @Environment(\.dismiss) var dismiss

    @StateObject private var viewModel = PushNotificationSettingsViewModel()

    public init() { }

    public var body: some View {
        NavigationView {
            if viewModel.didSetupNotifications {
                DataStateView(data: $viewModel.pushNotificationSettingsRequest,
                              retryHandler: { await viewModel.getNotificationSettings() }) { _ in
                    List {
                        Section(R.string.localizable.courseWideDiscussionNotificationsSectionTitle()) {
                            SettingsCell(viewModel: viewModel,
                                         type: .newCoursePost)
                            SettingsCell(viewModel: viewModel,
                                         type: .newReplyForCoursePost)
                            SettingsCell(viewModel: viewModel,
                                         type: .newAnnouncementPost)
                        }
                        Section(R.string.localizable.exerciseNotificationsSectionTitle()) {
                            SettingsCell(viewModel: viewModel,
                                         type: .exerciseReleased)
                            SettingsCell(viewModel: viewModel,
                                         type: .exercisePractice)
                            SettingsCell(viewModel: viewModel,
                                         type: .exerciseSubmissionAssessed)
                            SettingsCell(viewModel: viewModel,
                                         type: .fileSubmissionSuccessful)
                            SettingsCell(viewModel: viewModel,
                                         type: .newExercisePost)
                            SettingsCell(viewModel: viewModel,
                                         type: .newReplyForExercisePost)
                        }
                        Section(R.string.localizable.lectureNotificationsSectionTitle()) {
                            SettingsCell(viewModel: viewModel,
                                         type: .attachmentChange)
                            SettingsCell(viewModel: viewModel,
                                         type: .newLecturePost)
                            SettingsCell(viewModel: viewModel,
                                         type: .newReplyForLecturePost)
                        }
                        Section(R.string.localizable.tutorialGroupNotificationsSectionTitle()) {
                            SettingsCell(viewModel: viewModel,
                                         type: .tutorialGroupRegistrationStudent)
                            SettingsCell(viewModel: viewModel,
                                         type: .tutorialGroupDeleteUpdateStudent)
                        }
                        Section(R.string.localizable.tutorNotificationsSectionTitle()) {
                            SettingsCell(viewModel: viewModel,
                                         type: .tutorialGroupRegistrationTutor)
                            SettingsCell(viewModel: viewModel,
                                         type: .tutorialGroupAssignUnassignTutor)
                        }
                    }
                }.task {
                    await viewModel.getNotificationSettings()
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            viewModel.pushNotificationSettingsRequest = .loading
                            Task {
                                let isSuccessful = await viewModel.saveNotificationSettings()
                                if isSuccessful {
                                    dismiss()
                                }
                            }
                        }.disabled(viewModel.isSaveDisabled)
                    }
                }
                .navigationTitle("Notification Settings")
            } else {
                PushNotificationSetupView(shouldCloseOnSkip: true)
            }
        }
    }
}

struct SettingsCell: View {

    @ObservedObject var viewModel: PushNotificationSettingsViewModel

    let type: PushNotificationSettingId

    private var binding: Binding<Bool> {
        Binding(get: { viewModel.pushNotificationSettings[type]?.push ?? false },
                set: {
            viewModel.pushNotificationSettings[type]?.push = $0
            viewModel.isSaveDisabled = false
        })
    }

    var body: some View {
        if viewModel.pushNotificationSettings[type]?.push != nil {
            VStack(alignment: .leading, spacing: .s) {
                Toggle(isOn: binding) {
                    Text(type.title)
                        .font(.title3)
                        .lineLimit(2)
                }
                Text(type.description)
                    .font(.caption2)
                    .foregroundColor(Color.Artemis.secondaryLabel)
            }
        } else {
            EmptyView()
        }
    }
}

extension PushNotificationSettingId {

    var title: String {
        switch self {
        case .newCoursePost:
            return R.string.localizable.newCoursePostSettingsName()
        case .newReplyForCoursePost:
            return R.string.localizable.newReplyForCoursePostSettingsName()
        case .newAnnouncementPost:
            return R.string.localizable.newAnnouncementPostSettingsName()
        case .exerciseReleased:
            return R.string.localizable.exerciseReleasedSettingsName()
        case .exercisePractice:
            return R.string.localizable.exerciseOpenForPracticeSettingsName()
        case .exerciseSubmissionAssessed:
            return R.string.localizable.exerciseSubmissionAssessedSettingsName()
        case .fileSubmissionSuccessful:
            return R.string.localizable.fileSubmissionSuccessfulSettingsName()
        case .newExercisePost:
            return R.string.localizable.newExercisePostSettingsName()
        case .newReplyForExercisePost:
            return R.string.localizable.newReplyForExercisePostSettingsName()
        case .attachmentChange:
            return R.string.localizable.attachmentChangesSettingsName()
        case .newLecturePost:
            return R.string.localizable.newLecturePostSettingsName()
        case .newReplyForLecturePost:
            return R.string.localizable.newReplyForLecturePostSettingsName()
        case .tutorialGroupRegistrationStudent:
            return R.string.localizable.registrationTutorialGroupSettingsName()
        case .tutorialGroupDeleteUpdateStudent:
            return R.string.localizable.tutorialGroupUpdateDeleteSettingsName()
        case .tutorialGroupRegistrationTutor:
            return R.string.localizable.registrationTutorialGroupSettingsName()
        case .tutorialGroupAssignUnassignTutor:
            return R.string.localizable.assignUnassignTutorialGroupSettingsName()
        case .other:
            return "Error"
        }
    }

    var description: String {
        switch self {
        case .newCoursePost:
            return R.string.localizable.newCoursePostDescription()
        case .newReplyForCoursePost:
            return R.string.localizable.newReplyForCoursePostDescription()
        case .newAnnouncementPost:
            return R.string.localizable.newAnnouncementPostDescription()
        case .exerciseReleased:
            return R.string.localizable.exerciseReleasedDescription()
        case .exercisePractice:
            return R.string.localizable.exerciseOpenForPracticeDescription()
        case .exerciseSubmissionAssessed:
            return R.string.localizable.exerciseSubmissionAssessedDescription()
        case .fileSubmissionSuccessful:
            return R.string.localizable.fileSubmissionSuccessfulDescription()
        case .newExercisePost:
            return R.string.localizable.newExercisePostDescription()
        case .newReplyForExercisePost:
            return R.string.localizable.newReplyForExercisePostDescription()
        case .attachmentChange:
            return R.string.localizable.attachmentChangesDescription()
        case .newLecturePost:
            return R.string.localizable.newLecturePostDescription()
        case .newReplyForLecturePost:
            return R.string.localizable.newReplyForLecturePostDescription()
        case .tutorialGroupRegistrationStudent:
            return R.string.localizable.registrationTutorialGroupStudentDescription()
        case .tutorialGroupDeleteUpdateStudent:
            return R.string.localizable.tutorialGroupUpdateDeleteDescription()
        case .tutorialGroupRegistrationTutor:
            return R.string.localizable.registrationTutorialGroupTutorDescription()
        case .tutorialGroupAssignUnassignTutor:
            return R.string.localizable.assignUnassignTutorialGroupDescription()
        case .other:
            return "Error"
        }
    }
}
