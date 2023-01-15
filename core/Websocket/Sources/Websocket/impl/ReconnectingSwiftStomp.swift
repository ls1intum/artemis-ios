import Foundation
import RxSwift
import SwiftStompClient
import Data
import Device

class ReconnectingSwiftStomp {

    private let _connectedSession = BehaviorSubject<ReactiveSwiftStomp?>(value: nil)

    /**
     * Emits the latest session that is connected (and thus ready to be subscribed to).
     * Is null when no session is connected
     */
    var connectedSession: Observable<ReactiveSwiftStomp?> {
        _connectedSession
    }

    private let url: String

    private var currentSession: ReactiveSwiftStomp? = nil

    private var waitForNetworkStatusTask: Task<Void, Never>? = nil
    private var scheduleNewSessionTask: Task<Void, Never>? = nil

    init(url: String, networkStatusProvider: Observable<NetworkStatus>) {
        self.url = url

        let connectionAndNetworkStatus = Observable.combineLatest(
                _connectedSession.map { session in
                            if let s = session {
                                return s.connectionStatus as Observable<ConnectionStatus>
                            } else {
                                return Observable.of(ConnectionStatus.disconnected)
                            }
                        }
                        .switchLatest(),
                networkStatusProvider
        )

        //Schedule a task that calls startSession when internet is available and the current session is either unset or disconnected.
        scheduleNewSessionTask = Task {
            do {
                for try await data in connectionAndNetworkStatus.values {
                    let (isConnected, networkStatus) = data

                    switch networkStatus {
                    case .internet:
                        switch isConnected {
                        case .disconnected: startSession()
                        case .connecting: ()
                        case .connected: ()
                        }
                    case .unavailable:
                        _connectedSession.onNext(nil)
                    }
                }
            } catch {

            }
        }
    }

    private func startSession() {
        currentSession?.disconnect()
        waitForNetworkStatusTask?.cancel()

        let request = URLRequest(url: URL(string: url)!)
        let webSocket = WebSocket(request: request)

        let session = ReactiveSwiftStomp(webSocket: webSocket)
        currentSession = session

        waitForNetworkStatusTask = Task {
            session.connect()

            var alreadyConnected = false

//            do {
//                for try await connectionStatus in session.connectionStatus.publisher.values {
//                    switch connectionStatus {
//                    case .connected:
//                        print("CONNECTED SESSION")
//                        alreadyConnected = true
//                        _connectedSession.onNext(session)
//                    case .disconnected:
//                        if alreadyConnected {
//                            print("DISCONNECTED SESSION")
//
//                            _connectedSession.onNext(nil)
//                            return
//                        }
//                    case .connecting: ()
//                    }
//                }
//            } catch {
//                _connectedSession.onNext(nil)
//                return
//            }
        }
    }

    func cancel() {
        scheduleNewSessionTask?.cancel()
        waitForNetworkStatusTask?.cancel()
    }
}

fileprivate struct Session {
    let connectionStatus: ConnectionStatus
    let swiftStomp: ReactiveSwiftStomp?
}
