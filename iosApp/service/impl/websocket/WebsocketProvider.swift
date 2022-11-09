import Foundation
import RxSwift
import SwiftStomp

class WebsocketProvider {

    private let jsonProvider: JsonProvider
    private let serverCommunicationProvider: ServerCommunicationProvider
    private let accountService: AccountService

    private let session: Observable<ReactiveSwiftStomp>

    init(jsonProvider: JsonProvider, serverCommunicationProvider: ServerCommunicationProvider, accountService: AccountService) {
        self.jsonProvider = jsonProvider
        self.serverCommunicationProvider = serverCommunicationProvider
        self.accountService = accountService

        session =
                Observable.combineLatest(serverCommunicationProvider.host, accountService.authenticationData)
                .transformLatest { subscriber, data in
                    let (host, authData) = data

                    try! await subscriber.sendAll(publisher:
                    Observable.create { innerSub in
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

                        innerSub.onNext(session)

                        return Disposables.create {
                            session.disconnect()
                        }
                    }
                    )
                }
                .share(replay: 1, scope: .whileConnected)
    }

    func subscribe<T>(channel: String, type: T.Type) -> Observable<T> where T: Decodable {
        session.transformLatest { subscriber, currentSession in
            try! await subscriber.sendAll(publisher: currentSession.subscribe(destination: channel, type: type))
        }
    }
}
