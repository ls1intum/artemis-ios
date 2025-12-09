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
import Navigation

public struct LectureDetailView: View {

    @StateObject private var viewModel: LectureDetailViewModel

    public init(course: Course, lectureId: Int) {
        self._viewModel = StateObject(wrappedValue: LectureDetailViewModel(course: course, lectureId: lectureId))
    }

    public init(courseId: Int, lectureId: Int) {
        self._viewModel = StateObject(wrappedValue: LectureDetailViewModel(courseId: courseId, lectureId: lectureId))
    }

    public var body: some View {
        DataStateView(data: $viewModel.lecture,
                      retryHandler: { await viewModel.loadLecture() }) { lecture in
            ScrollView {
                HStack {
                    VStack(alignment: .leading, spacing: .l) {
                        if lecture.startDate != nil || lecture.description != nil || viewModel.channel.value != nil {
                            Text(R.string.localizable.overview())
                                .font(.title2).bold()

                            if let startDate = lecture.startDate {
                                Text(R.string.localizable.date())
                                    .font(.headline)
                                HStack {
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

                        if let attachments = lecture.attachments {
                            Text(R.string.localizable.attachments())
                                .font(.title2).bold()

                            ForEach(attachments, id: \.id) { attachment in
                                AttachmentCell(attachment: attachment)
                            }
                        }

                        Spacer()
                    }
                    Spacer()
                }.padding(.l)
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
        .task {
            await viewModel.loadLecture()
        }
        .alert(isPresented: $viewModel.showError, error: viewModel.error, actions: {})
    }
}

struct CompletePdfDownloadButton: View {

    @ObservedObject var viewModel: LectureDetailViewModel
    @State private var showDetails = false

    var body: some View {
        Button(action: {
            showDetails = true
        }) {
            Text(R.string.localizable.downloadCompletePdf())
        }
        .buttonStyle(ArtemisButton())
        .sheet(isPresented: $showDetails) {
            NavigationView {
                Group {
                    AttachmentUnitSheetContent(attachmentUnit: nil, lectureId: viewModel.lectureId, lectureName: viewModel.lecture.value?.title ?? "")
                }
                .navigationTitle(viewModel.lecture.value?.title ?? "")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(R.string.localizable.close()) {
                            showDetails = false
                        }
                    }
                }
            }
        }
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

private struct AttachmentCell: View {

    let attachment: Attachment

    @State private var showAttachmentSheet = false

    var body: some View {
        Button(action: {
            showAttachmentSheet = true
        }, label: {
            VStack(alignment: .leading) {
                HStack {
                    if let name = attachment.name {
                        Text(name)
                    }
                    if let pathExtension = attachment.pathExtension {
                        Chip(text: pathExtension, backgroundColor: .Artemis.artemisBlue)
                    }
                }
                HStack(spacing: 0) {
                    Text("(")
                    if let version = attachment.version {
                        Text("\(R.string.localizable.version()): \(version) -")
                    }
                    if let uploadDate = attachment.uploadDate {
                        Text("\(R.string.localizable.date()): \(uploadDate.shortDateAndTime)")
                    }
                    Text(")")
                }
                .font(.caption)
                .foregroundColor(.Artemis.secondaryLabel)
            }
        })
            .sheet(isPresented: $showAttachmentSheet) {
                LectureAttachmentSheet(attachment: attachment)
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

    @State private var showDetails = false

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
                showDetails = true
            }
            .sheet(isPresented: $showDetails) {
                NavigationView {
                    Group {
                        switch lectureUnit {
                        case .attachmentVideo(let lectureUnit):
                            AttachmentUnitSheetContent(attachmentUnit: lectureUnit)
                        case .text(let lectureUnit):
                            TextUnitSheetContent(textUnit: lectureUnit)
                        case .online(let lectureUnit):
                            OnlineUnitSheetContent(onlineUnit: lectureUnit)
                        case .unknown, .exercise:
                            EmptyView()
                        }
                    }
                        .navigationTitle(lectureUnit.baseUnit.name ?? "")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button(R.string.localizable.close()) {
                                    showDetails = false
                                }
                            }
                        }
                        .onAppear {
                            if !isCompleted.wrappedValue && lectureUnit.baseUnit.visibleToStudents ?? false {
                                isCompleted.wrappedValue = true
                            }
                        }
                }
            }
    }
}

struct TextUnitSheetContent: View {

    let textUnit: TextUnit

    var body: some View {
        ScrollView {
            ArtemisMarkdownView(string: textUnit.content ?? "")
                .padding(.horizontal)
        }
    }
}

struct AttachmentUnitSheetContent: View {

    let attachmentUnit: AttachmentVideoUnit?
    var lectureId: Int?
    var lectureName: String?

    @State private var showAttachment = false

    var body: some View {
        if let lectureId, let lectureName {
            LectureAttachmentSheet(attachment: nil, lectureId: lectureId, lectureName: lectureName)
        } else if let attachment = attachmentUnit?.attachment, attachmentUnit?.videoSource == nil {
            // Only attachment -> Make it full screen
            LectureAttachmentSheet(attachment: attachment)
        } else {
            ScrollView {
                if let attachment = attachmentUnit?.attachment {
                    NavigationLink {
                        LectureAttachmentSheet(attachment: attachment)
                    } label: {
                        BaseLectureUnitCell(viewModel: .init(courseId: nil, lectureId: nil),
                                            lectureUnit: .attachmentVideo(lectureUnit: attachmentUnit!))
                        .padding(.horizontal)
                        .allowsHitTesting(false)
                    }
                    .foregroundStyle(.primary)
                }
                if let videoSource = attachmentUnit?.videoSource,
                   let videoUrl = URL(string: videoSource) {
                    VideoUnitSheetContent(unit: attachmentUnit!, videoSource: videoUrl)
                } else {
                    Text(R.string.localizable.attachmentCouldNotBeOpened())
                        .foregroundColor(.red)
                }
            }
        }
    }
}

struct OnlineUnitSheetContent: View {

    let onlineUnit: OnlineUnit

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                if let description = onlineUnit.description {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(R.string.localizable.description())
                                .font(.headline)
                            Text(description)
                        }
                        Spacer()
                    }
                }
                if let source = onlineUnit.source,
                   let url = URL(string: source) {
                    Link(R.string.localizable.openLink(), destination: url)
                        .buttonStyle(ArtemisButton())
                } else {
                    Text(R.string.localizable.linkCouldNotBeLoaded())
                        .foregroundColor(.red)
                }
            }.padding(.l)
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
