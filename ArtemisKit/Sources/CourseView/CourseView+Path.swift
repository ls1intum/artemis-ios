//
//  CourseView+Path.swift
//
//
//  Created by Nityananda Zbil on 22.03.24.
//

import Navigation

public extension CoursePathView where Content == CourseView {
    init(path: CoursePath) {
        self.init(path: path, content: CourseView.init)
    }
}
