//
//  File.swift
//  
//
//  Created by Nityananda Zbil on 24.09.23.
//

import Common
import Dependencies
import SharedModels
import SharedServices
import SwiftUI
@testable import Dashboard

#Preview {
    NavigationStack {
        withDependencies { values in
            values.courseService = CourseServiceStub()
        } operation: {
            CoursesOverviewView(viewModel: withDependencies({ values in
                values.courseService = CourseServiceStub()
            }, operation: {
                CoursesOverviewViewModel()
            }))
        }
    }
    .modifier(AppStorePreview(title: "Manage all of your courses in one app"))
}
