//
//  LectureDetailView.swift
//  
//
//  Created by Sven Andabaka on 30.04.23.
//

import SwiftUI
import Common
import SharedModels
import ArtemisMarkdown
import DesignLibrary
import Iris
import Navigation

public struct LectureDetailView: View {

    @Environment(\.availableTabs) private var tabs
    @EnvironmentObject private var navigationController: NavigationController
    @StateObject private var viewModel: LectureDetailViewModel
    private let target: LectureMediaTarget?

    public init(course: CourseForOverviewDTO, lectureId: Int, target: LectureMediaTarget? = nil) {
        self.target = target
        self._viewModel = StateObject(wrappedValue: LectureDetailViewModel(course: course, lectureId: lectureId))
    }

    public init(courseId: Int, lectureId: Int, target: LectureMediaTarget? = nil) {
        self.target = target
        self._viewModel = StateObject(wrappedValue: LectureDetailViewModel(courseId: courseId, lectureId: lectureId))
    }

    init(viewModel: LectureDetailViewModel, target: LectureMediaTarget?) {
        self.target = target
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        DataStateView(data: $viewModel.lecture,
                      retryHandler: { await viewModel.loadLecture() }) { lecture in
            ScrollView {
                VStack(alignment: .leading, spacing: .l) {
                    if lecture.startDate != nil || lecture.description != nil || viewModel.channel.value != nil {
                        Text(R.string.localizable.overview())
                            .font(.title2).bold()

                        if tabs.iris {
                            AskIrisButton(courseId: viewModel.courseId, lecture: lecture)
                        }

                        if let startDate = lecture.startDate {
                            Text(R.string.localizable.date())
                                .font(.headline)
                            HStack(spacing: 0) {
                                Text("\(startDate.shortDateAndTime)")
                                if let endDate = lecture.endDate {
                                    Text(" - \(endDate.shortDateAndTime)")
                                }
                            }
                        }

                        if let description = lecture.description {
                            Text(R.string.localizable.description())
                                .font(.headline)
                            ArtemisMarkdownView(string: description)
                        }

                        if let channel = viewModel.channel.value {
                            Text(R.string.localizable.communication())
                                .font(.headline)
                            ChannelCell(courseId: viewModel.courseId, channel: channel)
                        }
                    }

                    if let lectureUnits = lecture.lectureUnits {
                        HStack {
                            Text(R.string.localizable.lectureUnits())
                                .font(.title2).bold()
                            if viewModel.shouldShowDownloadCompletePDFButton {
                                CompletePdfDownloadButton(viewModel: viewModel)
                            }
                        }

                        ForEach(lectureUnits, id: \.id) { lectureUnit in
                            LectureUnitCell(viewModel: viewModel, lectureUnit: lectureUnit)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.l)
            }
            .onChange(of: viewModel.course.value, initial: true) { _, newValue in
                if newValue != nil {
                    Task {
                        await viewModel.loadAssociatedChannel()
                    }
                }
            }
        }
        .navigationTitle(viewModel.lecture.value?.title ?? R.string.localizable.loading())
        .navigationBarTitleDisplayMode(.inline)
        .task(id: target) {
            viewModel.configureTarget(target)
            await viewModel.loadLecture()
        }
        .onReceive(viewModel.$targetPresentation) { presentation in
            guard let presentation, let target = presentation.target else { return }
            navigationController.openLectureMedia(courseId: viewModel.courseId, lectureId: viewModel.lectureId, target: target)
            viewModel.targetPresentation = nil
        }
        .onReceive(NotificationCenter.default.publisher(for: .lectureUnitCompletionDidChange)) { event in
            guard event.userInfo?["courseId"] as? Int == viewModel.courseId,
                  event.userInfo?["lectureId"] as? Int == viewModel.lectureId else { return }
            Task { await viewModel.loadLecture() }
        }
        .alert(isPresented: $viewModel.showError, error: viewModel.error, actions: {})
    }
}

struct CompletePdfDownloadButton: View {
    @EnvironmentObject private var navigationController: NavigationController
    @ObservedObject var viewModel: LectureDetailViewModel

    var body: some View {
        Button(R.string.localizable.downloadCompletePdf()) {
            navigationController.openLectureMedia(courseId: viewModel.courseId, lectureId: viewModel.lectureId)
        }
        .buttonStyle(ArtemisButton())
    }
}

private struct ChannelCell: View {

    @EnvironmentObject var navigationController: NavigationController
    let courseId: Int
    let channel: Channel

    var body: some View {
        Button {
            navigationController.outerPath = NavigationPath()
            navigationController.tabPath.append(ConversationPath(id: channel.id, coursePath: CoursePath(id: courseId)))
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: .l) {
                    Label {
                        let name = channel.conversationName
                        let displayName = name
                            .suffix(name.starts(with: "lecture-") ? name.count - 8 : name.count)
                        Text(String(displayName))
                    } icon: {
                        channel.icon?
                            .scaledToFit()
                            .frame(height: 22)
                    }
                    .font(.title3)

                    if let description = channel.description {
                        Text(description)
                    }
                }
                .foregroundColor(Color.Artemis.primaryLabel)
                Spacer()
                Image(systemName: "chevron.forward")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.l)
            .cardModifier(backgroundColor: .Artemis.exerciseCardBackgroundColor, cornerRadius: .m)
        }
    }
}

private struct LectureUnitCell: View {

    @ObservedObject var viewModel: LectureDetailViewModel

    let lectureUnit: LectureUnit

    var body: some View {
        Group {
            switch lectureUnit {
            case .exercise(let lectureUnit):
                if let exercise = lectureUnit.exercise,
                   let course = viewModel.course.value {
                    ExerciseListCell(course: course, exercise: exercise)
                } else {
                    Text(R.string.localizable.exerciseCouldNotBeLoaded())
                        .artemisStyleCard()
                }
            case .unknown:
                EmptyView()
            default:
                BaseLectureUnitCell(viewModel: viewModel, lectureUnit: lectureUnit)
            }
        }
    }
}

struct BaseLectureUnitCell: View {

    @ObservedObject var viewModel: LectureDetailViewModel

    @State private var lectureUnit: LectureUnit
    @State private var isLoading = false
    @EnvironmentObject private var navigationController: NavigationController

    private var isCompleted: Binding<Bool> {
        Binding(get: {
            lectureUnit.baseUnit.completed ?? false
        }, set: { completed in
            isLoading = true
            Task {
                lectureUnit = await viewModel.updateLectureUnitCompletion(lectureUnit: lectureUnit, completed: completed)
                isLoading = false
            }
        })
    }

    init(viewModel: LectureDetailViewModel, lectureUnit: LectureUnit) {
        self.viewModel = viewModel
        self._lectureUnit = State(initialValue: lectureUnit)
    }

    var body: some View {
        HStack(spacing: .l) {
            lectureUnit.baseUnit.image
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundColor(Color.Artemis.primaryLabel)
                .frame(width: .smallImage)

            Text(lectureUnit.baseUnit.name ?? "")
                .font(.title3)

            Spacer(minLength: 0)

            if !(lectureUnit.baseUnit.visibleToStudents ?? false) {
                Chip(text: R.string.localizable.notReleased(), backgroundColor: .Artemis.badgeWarningColor)
            } else {
                if isLoading {
                    ProgressView()
                } else {
                    RoundGreenCheckbox(isChecked: isCompleted)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.l)
        .cardModifier(backgroundColor: .Artemis.exerciseCardBackgroundColor, cornerRadius: .m)
        .onTapGesture {
            navigationController.openLectureMedia(courseId: viewModel.courseId, lectureId: viewModel.lectureId,
                                                  target: LectureMediaTarget(unitId: lectureUnit.id))
        }
        .onChange(of: viewModel.lecture.value, initial: true) { _, _ in
            if let fresh = viewModel.lecture.value?.lectureUnits?.first(where: { $0.id == lectureUnit.id }) {
                lectureUnit = fresh
            }
        }
    }
}

struct TextUnitContent: View {

    let textUnit: TextUnit

    var body: some View {
        ScrollView {
            ArtemisMarkdownView(string: textUnit.content ?? "")
                .padding(.horizontal)
        }
    }
}

struct OnlineUnitContent: View {

    let onlineUnit: OnlineUnit

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                if let description = onlineUnit.description {
                    Text(R.string.localizable.description())
                        .font(.headline)
                    Text(description)
                }
                if let source = onlineUnit.source, let url = URL(string: source) {
                    Link(R.string.localizable.openLink(), destination: url)
                        .buttonStyle(ArtemisButton())
                } else {
                    Text(R.string.localizable.linkCouldNotBeLoaded())
                        .foregroundColor(.red)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.l)
        }
    }
}

struct RoundGreenCheckbox: View {
    @Binding var isChecked: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(isChecked ? Color.green : Color.gray)
                .frame(width: 24, height: 24)
                .overlay(
                    Circle()
                        .stroke(isChecked ? Color.green : Color.gray, lineWidth: 2)
                )
                .onTapGesture {
                    isChecked.toggle()
                }

            if isChecked {
                Image(systemName: "checkmark")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.white)
                    .frame(width: 12, height: 12)
            }
        }
        .animation(.easeInOut, value: isChecked)
    }
}

struct LectureUnitPresentation: Identifiable {
    let unit: LectureUnit
    var target: LectureMediaTarget?
    var studentVersion: String?
    var id: Int64 { unit.id }
}

struct LectureUnitContent: View {
    let unit: LectureUnit
    let identity: String
    var explicitPage: Int?
    var originalSlideNumber: Int?
    var visibleSlideNumbers: [Int]?
    var studentVersion: String?
    var refreshSlide: (() async -> DataState<LectureSlideAccess>)?

    var body: some View {
        switch unit {
        case .attachmentVideo(let attachment):
            AttachmentUnitContent(
                attachmentUnit: attachment,
                identity: identity,
                explicitPage: explicitPage,
                originalSlideNumber: originalSlideNumber,
                visibleSlideNumbers: visibleSlideNumbers,
                studentVersion: studentVersion,
                refreshSlide: refreshSlide
            )
        case .text(let text): TextUnitContent(textUnit: text)
        case .online(let online): OnlineUnitContent(onlineUnit: online)
        case .unknown, .exercise:
            ContentUnavailableView("Lecture unit is unavailable", systemImage: "doc.questionmark")
        }
    }
}
