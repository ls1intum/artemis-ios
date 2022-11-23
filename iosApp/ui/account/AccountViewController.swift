import Foundation
import Factory
import Data
import Datastore

@MainActor class AccountViewController: ObservableObject {

    private let serverConfigurationService: ServerConfigurationService = Container.serverConfigurationService()

    @Published var serverProfileInfo: DataState<ProfileInfo> = DataState.loading
}
