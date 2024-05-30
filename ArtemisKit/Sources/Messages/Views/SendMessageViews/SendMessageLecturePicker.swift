//
//  SendMessageLecturePicker.swift
//
//
//  Created by Nityananda Zbil on 29.10.23.
//

import SharedModels
import SwiftUI

struct SendMessageLecturePicker: View {

    let delegate: SendMessagePickerDelegate

    let course: Course

    var body: some View {
        Group {
            if let lectures = course.lectures, !lectures.isEmpty {
                List(lectures) { lecture in
                    if let title = lecture.title {
                        Button(title) {
                            delegate.pickerDidSelect("[lecture]\(title)(/courses/\(course.id)/lectures/\(lecture.id))[/lecture]")
                        }
                    }
                }
                .listStyle(.plain)
            } else {
                ContentUnavailableView(R.string.localizable.lecturesUnavailable(), systemImage: "magnifyingglass")
            }
        }
        .navigationTitle("Lectures")
        .navigationBarTitleDisplayMode(.inline)
    }
}
