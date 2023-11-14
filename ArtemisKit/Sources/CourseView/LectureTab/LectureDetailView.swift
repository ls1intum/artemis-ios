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
                        if let lectureUnits = lecture.lectureUnits {
                            Text(R.string.localizable.lectureUnits())
                                .font(.headline)
                            ForEach(lectureUnits, id: \.id) { lectureUnit in
                                LectureUnitCell(viewModel: viewModel, lectureUnit: lectureUnit)
                            }
                        }
                        if let attachments = lecture.attachments {
                            Text(R.string.localizable.attachments())
                                .font(.headline)
                            ForEach(attachments, id: \.id) { attachment in
                                AttachmentCell(attachment: attachment)
                            }
                        }
                        Spacer()
                    }
                    Spacer()
                }.padding(.l)
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

private struct AttachmentCell: View {

    let attachment: Attachment

    @State private var showAttachmentSheet = false

    var pathExtension: String? {
        guard let name = (attachment.baseAttachment as? FileAttachment)?.link else { return nil }
        let filename: NSString = name as NSString
        return filename.pathExtension.uppercased()
    }

    var body: some View {
        Button(action: {
            showAttachmentSheet = true
        }, label: {
            VStack(alignment: .leading) {
                HStack {
                    if let name = attachment.baseAttachment.name {
                        Text(name)
                    }
                    if let pathExtension {
                        Chip(text: pathExtension, backgroundColor: .Artemis.artemisBlue)
                    }
                }
                if let fileAttachment = attachment.baseAttachment as? FileAttachment {
                    HStack(spacing: 0) {
                        Text("(")
                        if let version = fileAttachment.version {
                            Text("\(R.string.localizable.version()): \(version) -")
                        }
                        if let uploadDate = fileAttachment.uploadDate {
                            Text("\(R.string.localizable.date()): \(uploadDate.shortDateAndTime)")
                        }
                        Text(")")
                    }
                        .font(.caption)
                        .foregroundColor(.Artemis.secondaryLabel)
                }
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
                    Text(R.string.localizable.exercisecouldNotBeLoaded())
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
        HStack {
            lectureUnit.baseUnit.image
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundColor(Color.Artemis.primaryLabel)
                .frame(width: .smallImage)

            Text(lectureUnit.baseUnit.name ?? "")
                .font(.title3)

            Spacer()

            if !(lectureUnit.baseUnit.visibleToStudents ?? false) {
                Chip(text: R.string.localizable.notReleased(), backgroundColor: .Artemis.badgeWarningColor)
            } else {
                if isLoading {
                    ProgressView()
                } else {
                    Toggle("", isOn: isCompleted)
                }
            }
        }
            .frame(maxWidth: .infinity)
            .padding(.l)
            .artemisStyleCard()
            .onTapGesture {
                showDetails = true
            }
            .sheet(isPresented: $showDetails) {
                NavigationView {
                    Group {
                        switch lectureUnit {
                        case .attachment(let lectureUnit):
                            AttachmentUnitSheetContent(attachmentUnit: lectureUnit)
                        case .text(let lectureUnit):
                            TextUnitSheetContent(textUnit: lectureUnit)
                        case .video(let lectureUnit):
                            VideoUnitSheetContent(videoUnit: lectureUnit)
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
        }
    }
}

struct AttachmentUnitSheetContent: View {

    let attachmentUnit: AttachmentUnit

    @State private var showAttachment = false

    var body: some View {
        if let attachment = attachmentUnit.attachment {
            LectureAttachmentSheet(attachment: attachment)
        } else {
            Text(R.string.localizable.attachmentCouldNotBeOpened())
                .foregroundColor(.red)
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

struct VideoUnitSheetContent: View {

    let videoUnit: VideoUnit

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                if let description = videoUnit.description {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(R.string.localizable.description())
                                .font(.headline)
                            Text(description)
                        }
                        Spacer()
                    }
                }
                if let source = videoUnit.source,
                   let url = URL(string: source) {
                    Link(R.string.localizable.openVideo(), destination: url)
                        .buttonStyle(ArtemisButton())
                } else {
                    Text(R.string.localizable.videoCanNotBeLoaded())
                        .foregroundColor(.red)
                }
            }.padding(.l)
        }
    }
}
