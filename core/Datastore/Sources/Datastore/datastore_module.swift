import Foundation
import Factory
import Model
import Data

public extension Container {
    static let serverCommunicationProvider = Factory<ServerCommunicationProvider> {
        ServerCommunicationProviderImpl()
    }

    static let accountService = Factory<AccountService>(scope: .singleton) {
        AccountServiceImpl(
                serverCommunicationProvider: serverCommunicationProvider(),
                jsonProvider: jsonProvider(),
                networkStatusProvider: networkStatusProvider(),
                loginService: loginService(),
                serverDataService: serverDataService()
        )
    }
}