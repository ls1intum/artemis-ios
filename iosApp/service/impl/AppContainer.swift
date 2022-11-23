import Factory
import Data
import Device
import Datastore

/**
 * Dependency injection container for this app.
 */
extension Container {

    static let websocketProvider = Factory<WebsocketProvider>(scope: .singleton) {
        WebsocketProvider(jsonProvider: jsonProvider(), serverCommunicationProvider: serverCommunicationProvider(), accountService: accountService(), networkStatusProvider: networkStatusProvider())
    }

    static let participationService = Factory<ParticipationService>(scope: .singleton) {
        ParticipationServiceImpl(
                websocketProvider: websocketProvider(),
                serverCommunicationProvider: serverCommunicationProvider(),
                networkStatusProvider: networkStatusProvider(),
                accountService: accountService(),
                jsonProvider: jsonProvider()
        )
    }
}
