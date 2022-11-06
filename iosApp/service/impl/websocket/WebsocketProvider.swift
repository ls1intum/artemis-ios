import Foundation
import Combine
import SwiftStomp

class WebsocketProvider {

    private let jsonProvider: JsonProvider
    private let serverCommunicationProvider: ServerCommunicationProvider
    private let accountService: AccountService

    private let session: AnyPublisher<ReactiveSwiftStomp, Never>

    init(jsonProvider: JsonProvider, serverCommunicationProvider: ServerCommunicationProvider, accountService: AccountService) {
        self.jsonProvider = jsonProvider
        self.serverCommunicationProvider = serverCommunicationProvider
        self.accountService = accountService

        session = serverCommunicationProvider.host
                .combineLatest(accountService.authenticationData)
                .transformLatest { subscriber, data in
                    let (host, authData) = data

                    try! await subscriber.sendAll(publisher:
                    AnyPublisher.create { innerSub in
                        var url = "wss://" + host + "/websocket/tracker/websocket"
                        switch authData {
                        case .NotLoggedIn:
                            url = url
                        case .LoggedIn(authToken: let authToken, _):
                            url += "?access_token=" + authToken
                        }

                        let swiftStomp = SwiftStomp(host: URL(string: url)!)
                        let session = ReactiveSwiftStomp(swiftStomp: swiftStomp, jsonProvider: jsonProvider)
                        session.connect()

                        innerSub.send(session)

                        return AnyCancellable {
                            session.disconnect()
                        }
                    }
                    )
                }
                .share(replay: 1)
                .eraseToAnyPublisher()
    }


}
