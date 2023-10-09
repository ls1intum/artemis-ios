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

struct CoursesOverviewView_Previews: PreviewProvider {

    static var previews: some View {
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
    }
}
