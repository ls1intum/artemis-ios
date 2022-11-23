import Foundation
import Factory
import Data
import Model
import Device
import Datastore

public extension Container {
    static let websocketProvider = Factory<WebsocketProvider>(scope: .singleton) {
        WebsocketProvider(jsonProvider: jsonProvider(), serverConfigurationService: serverConfigurationService(), accountService: accountService(), networkStatusProvider: networkStatusProvider())
    }

    static let participationService = Factory<ParticipationService>(scope: .singleton) {
        ParticipationServiceImpl(
                websocketProvider: websocketProvider(),
                serverConfigurationService: serverConfigurationService(),
                networkStatusProvider: networkStatusProvider(),
                accountService: accountService(),
                jsonProvider: jsonProvider()
        )
    }
}