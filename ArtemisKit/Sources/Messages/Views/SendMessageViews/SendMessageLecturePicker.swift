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

    let delegate: SendMessagePickerDelegate

    var body: some View {
        Group {
            if let lectures = viewModel.course.lectures, !lectures.isEmpty {
                List(lectures) { lecture in
                    view(lecture: lecture)
                }
                .listStyle(.plain)
            } else {
                ContentUnavailableView(R.string.localizable.lecturesUnavailable(), systemImage: "magnifyingglass")
            }
        }
        .task {
            await viewModel.task()
        }
        .navigationTitle("Lectures")
        .navigationBarTitleDisplayMode(.inline)
    }
}

@MainActor
extension SendMessageLecturePicker {
    init(course: Course, delegate: SendMessagePickerDelegate) {
        self.init(viewModel: SendMessageLecturePickerViewModel(course: course), delegate: delegate)
    }

    @ViewBuilder
    func view(lecture: Lecture) -> some View {
        if let title = lecture.title {
            NavigationLink {
                Group {
                    List {
                        Button(title) {
                            delegate.pickerDidSelect(
                                "[lecture]\(title)(/courses/\(viewModel.course.id)/lectures/\(lecture.id))[/lecture]"
                            )
                        }
                        ForEach(viewModel.lectureUnits, id: \.id) { lectureUnit in
                            view(lectureUnit: lectureUnit)
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
    func view(lectureUnit: LectureUnit) -> some View {
        if let name = lectureUnit.baseUnit.name {
            NavigationLink {
                Group {
                    List {
                        Button {
                            delegate.pickerDidSelect(
                                "Lecture unit: \(name)"
                            )
                        } label: {
                            Text(name)
                        }
                        if case let .attachment(attachment) = lectureUnit, let slides = attachment.slides {
                            ForEach(slides, id: \.id) { slide in
                                view(slide: slide)
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
    func view(slide: Slide) -> some View {
        if let slideImagePath = slide.slideImagePath, let slideNumber = slide.slideNumber {
            Button {
                print(slideImagePath)
            } label: {
                Text("Slide \(slideNumber)")
            }
        }
    }
}
