//
//  SendMessageLecturePicker.swift
//
//
//  Created by Nityananda Zbil on 29.10.23.
//

import SharedModels
import SwiftUI

struct SendMessageLecturePicker: View {

    @State var viewModel: SendMessageLecturePickerViewModel

    var body: some View {
        Group {
            if let lectures = viewModel.course.lectures, !lectures.isEmpty {
                List(lectures) { lecture in
                    rowContent(lecture: lecture)
                }
                .listStyle(.plain)
            } else {
                ContentUnavailableView(R.string.localizable.lecturesUnavailable(), systemImage: "magnifyingglass")
            }
        }
        .task {
            await viewModel.task()
        }
        .navigationTitle(R.string.localizable.lectures())
        .navigationBarTitleDisplayMode(.inline)
    }
}

@MainActor
extension SendMessageLecturePicker {
    init(course: Course, delegate: SendMessageMentionContentDelegate) {
        self.init(viewModel: SendMessageLecturePickerViewModel(course: course, delegate: delegate))
    }
}

@MainActor
private extension SendMessageLecturePicker {
    @ViewBuilder
    func rowContent(lecture: Lecture) -> some View {
        if let title = lecture.title {
            NavigationLink {
                Group {
                    List {
                        Button(title) {
                            viewModel.select(lecture: lecture)
                        }
                        ForEach(viewModel.lectureUnits, id: \.id) { lectureUnit in
                            rowContent(lectureUnit: lectureUnit)
                        }
                    }
                    .listStyle(.plain)
                }
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
            } label: {
                Text(title)
            }
        }
    }

    @ViewBuilder
    func rowContent(lectureUnit: LectureUnit) -> some View {
        if let name = lectureUnit.baseUnit.name {
            NavigationLink {
                Group {
                    List {
                        Button {
                            viewModel.select(lectureUnit: lectureUnit)
                        } label: {
                            Text(name)
                        }
                        if case let .attachment(attachment) = lectureUnit, let slides = attachment.slides {
                            ForEach(slides, id: \.id) { slide in
                                rowContent(lectureUnit: lectureUnit, slide: slide)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
                .navigationTitle(name)
                .navigationBarTitleDisplayMode(.inline)
            } label: {
                Text(name)
            }
        }
    }

    @ViewBuilder
    func rowContent(lectureUnit: LectureUnit, slide: Slide) -> some View {
        if let slideImagePath = slide.slideImagePath, let slideNumber = slide.slideNumber {
            Button {
                viewModel.select(lectureUnit: lectureUnit, slide: slide)
            } label: {
                Text(R.string.localizable.mentionSlideNumber(slideNumber))
            }
        }
    }
}
