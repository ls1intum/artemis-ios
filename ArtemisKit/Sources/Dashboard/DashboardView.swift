import Account
import Common
import CourseRegistration
import CourseView
import DesignLibrary
import Navigation
import Notifications
import SharedModels
import SwiftUI

/// Display the course grid.
public struct DashboardView: View {

    @State private var viewModel = DashboardViewModel()

    public init() {}

    public var body: some View {
        CourseGrid(viewModel: viewModel)
            .navigationTitle(Text(R.string.localizable.dashboardTitle()))
            .navigationBarBackButtonHidden()
            .accountMenu(error: Binding(
                get: {
                    viewModel.error
                }, set: { error in
                    if let error {
                        viewModel.error = error
                        viewModel.showError = true
                    }
                })
            )
            .notificationToolbar()
            .alert(isPresented: $viewModel.showError, error: viewModel.error, actions: {})
    }
}
