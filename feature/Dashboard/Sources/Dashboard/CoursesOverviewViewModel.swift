import Foundation
import SwiftUI
import Factory
import Combine
import RxSwift
import Model
import Data
import Device
import Datastore

extension CoursesOverviewView {
    @MainActor class CoursesOverviewViewModel: ObservableObject {

        var dashboardService: DashboardService = Container.dashboardService()
        var accountService: AccountService = Container.accountService()
        var serverConfigurationService: ServerConfigurationService = Container.serverConfigurationService()
        let networkStatusProvider: NetworkStatusProvider = Container.networkStatusProvider()

        @Published var dashboard: DataState<Dashboard> = DataState.loading
        @Published var bearer: String = ""

        @Published var serverUrl: String = ""

        private let requestReloadDashboard = PublishSubject<Void>()

        init() {
            accountService
                    .authenticationData
                    .publisher
                    .replaceError(with: AuthenticationData.NotLoggedIn)
                    .receive(on: DispatchQueue.main)
                    .map { authData in
                        switch authData {
                        case .NotLoggedIn:
                            return ""
                        case .LoggedIn(authToken: let authToken, _):
                            return "Bearer " + authToken
                        }
                    }
                    .assign(to: &$bearer)

            serverConfigurationService
                    .serverUrl
                    .publisher
                    .replaceError(with: "")
                    .receive(on: DispatchQueue.main)
                    .assign(to: &$serverUrl)

            let dashboardPublisher: Observable<DataState<Dashboard>> =
                    Observable
                            .combineLatest(
                                    accountService.authenticationData,
                                    serverConfigurationService.serverUrl,
                                    requestReloadDashboard.startWith(())
                            )
                            .transformLatest { [self] (continuation, data) in
                                let (authData, serverUrl, _) = data
                                switch authData {
                                case .LoggedIn(authToken: let authToken, _):
                                    try? await continuation.sendAll(publisher:
                                    retryOnInternet(connectivity: networkStatusProvider.currentNetworkStatus) { [self] in
                                        await dashboardService.loadDashboard(authorizationToken: authToken, serverUrl: serverUrl)
                                    }
                                    )
                                case .NotLoggedIn: continuation.onNext(DataState<Dashboard>.suspended(error: nil))
                                }
                            }


            dashboardPublisher
                    .publisher
                    .replaceWithDataStateError()
                    .receive(on: DispatchQueue.main)
                    .assign(to: &$dashboard)
        }

        func reloadDashboard() async {
            requestReloadDashboard.onNext(())
        }

        func logout() {
            accountService.logout()
        }
    }
}
