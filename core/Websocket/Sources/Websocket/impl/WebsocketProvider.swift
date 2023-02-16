import Foundation
import RxSwift
import SwiftStompClient
import Model
import Device

public class WebsocketProvider {

    //    private let session: Observable<ReactiveSwiftStomp?>

    init() {

        //        session =
        //                Observable
        //                        .transformLatest { subscriber, data in
        //                            let (host, authData) = data
        //
        //                            do {
        //                                try await subscriber.sendAll(
        //                                        publisher: Observable.create { innerSub in
        //                                                    print("START RESTARTING WEBSOCKET")
        //                                            var url = "wss://" + Config.host + "/websocket/tracker/websocket"
        //                                                    switch authData {
        //                                                    case .NotLoggedIn:
        //                                                        url = url
        //                                                    case .LoggedIn(authToken: let authToken, _):
        //                                                        url += "?access_token=" + authToken
        //                                                    }
        //
        //                                                    let reconnectingSwiftStomp = ReconnectingSwiftStomp(
        //                                                            url: url
        //                                                    )
        //
        //                                                    innerSub.onNext(reconnectingSwiftStomp.connectedSession)
        //
        //                                                    return Disposables.create {
        //                                                        print("STOP RESTARTING WEBSOCKET")
        //                                                        reconnectingSwiftStomp.cancel()
        //                                                    }
        //                                                }
        //                                                .switchLatest()
        //                                )
        //                            } catch {
        //                                return
        //                            }
        //                        }
        //                        .share(replay: 1, scope: .whileConnected)
    }

    //    public func subscribe<T>(channel: String, type: T.Type) -> Observable<T> where T: Decodable {
    //        session.map { (currentSession: ReactiveSwiftStomp?) in
    //                    guard let connectedSession = currentSession else {
    //                        return Observable<T>.empty()
    //                    }
    //
    //                    return Observable.create { sub in
    //                        let t = Task {
    //                            do {
    //                                try await sub.sendAll(publisher: connectedSession.subscribe(destination: channel, type: type))
    //                            } catch {
    //                            }
    //                        }
    //
    //                        return Disposables.create {
    //                            t.cancel()
    //                        }
    //                    }
    //                }
    //                .switchLatest()
    //        session.transformLatest { subscriber, currentSession in
    //            try! await subscriber.sendAll(publisher: currentSession.subscribe(destination: channel, type: type))
    //        }
    //    }
}
