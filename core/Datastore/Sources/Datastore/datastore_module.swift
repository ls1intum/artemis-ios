import Foundation
import Factory
import Model
import Data

public extension Container {
    static let serverConfigurationService = Factory<ServerConfigurationService> {
        ServerConfigurationServiceImpl()
    }

    static let accountService = Factory<AccountService>(scope: .singleton) {
        AccountServiceImpl(
                serverConfigurationService: serverConfigurationService(),
                jsonProvider: jsonProvider(),
                networkStatusProvider: networkStatusProvider(),
                serverDataService: serverDataService()
        )
    }
}
