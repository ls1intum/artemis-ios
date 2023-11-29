import Account
import Common
import CourseRegistration
import CourseView
import DesignLibrary
import Navigation
import Notifications
import SharedModels
import SwiftUI

/**
 * Display the course overview with the course list.
 */
public struct DashboardView: View {

    @StateObject private var viewModel = DashboardViewModel()

    public init() {}

    public var body: some View {
        CourseCollectionView(viewModel: viewModel)
            .navigationTitle(Text(R.string.localizable.dashboard_title()))
            .navigationBarBackButtonHidden()
            .accountMenu(error: Binding(
                get: {
                    viewModel.error
                }, set: { error in
                    if let error {
                        viewModel.presentError(userFacingError: error)
                    }
                })
            )
            .notificationToolBar()
            .alert(isPresented: $viewModel.showError, error: viewModel.error, actions: {})
    }
}
