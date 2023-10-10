//
//  File.swift
//
//
//  Created by Nityananda Zbil on 10.10.23.
//

import Common
import Dependencies
import Navigation
import SharedModels
import SharedServices
import SwiftUI

struct CoursesView_Previews: PreviewProvider {

    static var previews: some View {
        NavigationStack {
            CourseView(viewModel: withDependencies({ values in
                values.courseService = CourseServiceStub()
            }, operation: {
                CourseViewModel(courseId: 1)
            }), courseId: 1)
            .environmentObject({ () -> NavigationController in
                let navigationController = NavigationController()
                navigationController.courseTab = .exercise
                return navigationController
            }())
        }
    }
}
