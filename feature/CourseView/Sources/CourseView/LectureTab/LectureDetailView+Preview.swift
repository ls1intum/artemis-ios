//
//  File.swift
//  
//
//  Created by Nityananda Zbil on 10.10.23.
//

import Dependencies
import SwiftUI

#Preview {
    NavigationStack {
        LectureDetailView(viewModel: withDependencies({ values in
            values.courseService = CourseServiceStub()
            values.lectureService = LectureServiceStub()
        }, operation: {
            LectureDetailViewModel(courseId: 1, lectureId: 1)
        }))
    }
}
