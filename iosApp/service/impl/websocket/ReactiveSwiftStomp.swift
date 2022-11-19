import Foundation
import SwiftStompClient
import RxSwift
import Semaphore

class ReactiveSwiftStomp: StompProtocol {

    private let swiftStomp: SwiftStompClient

    private let subscriptionMutex = AsyncSemaphore(value: 1)

    //Accesses must be guarded by the mutex to guarantee thread safety
    private var subscriptionCounter: [String: Int] = [:]

    private var pingTask: Task<Void, Never>? = nil

    let connectionStatus = BehaviorSubject<ConnectionStatus>(value: .connecting)

    init(webSocket: WebSocket, jsonProvider: JsonProvider) {
        self.swiftStomp = SwiftStompClient(webSocket: webSocket, heartBeat: HeartBeat(clientHeartBeating: "10000,10000"))
        self.jsonProvider = jsonProvider

        swiftStomp.stompDelegate = self
    }

    private let jsonProvider: JsonProvider

    private var messagePublisher = PublishSubject<StompMessage>()

    func connect() {
        swiftStomp.openWebSocketConnection()
    }

    func disconnect() {
        swiftStomp.closeWebSocketConnection()
    }

    func handleWebSocketConnect(session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol: String?) {
        swiftStomp.sendFrame(frame: ConnectStompFrame(acceptVersion: "1.2", heartBeat: "10000,10000"))
    }

    func clientReceiveFrame(stomp: SwiftStompClient, frameType: SwiftStompClient.FrameResponseKeys, headers: [String: String], body: String?) {
        switch frameType {
        case .connected:
            print("Connected")
            connectionStatus.onNext(.connected)
        case .message:
            guard let message: String = body else {
                print("Received empty message")
                return
            }

            guard let destination = headers["destination"] else {
                print("No destination for message")
                return
            }

            print("Received on " + destination + ": " + message)

            messagePublisher.onNext(StompMessage(destination: destination, text: String(message.dropLast())))
        case .receipt: ()
//            print("receipt")
        case .error:
            print("error: " + (body ?? "no body"))
        case .ping: ()
//            print("ping")
        }
    }

    func subscribe<T>(destination: String, type: T.Type) -> Observable<T> where T: Decodable {
        let id = UUID().uuidString

        return Observable.create { [self] sub in
                    let t = Task {
                        do {
                            //Guard the access using a mutex.
                            try await subscriptionMutex.waitUnlessCancelled()
                            let currentCounter = subscriptionCounter[destination] ?? 0

                            //Only subscribe if the destination does not have a subscriber yet.
                            if currentCounter == 0 {
                                print("Sub to " + destination)
                                swiftStomp.sendFrame(frame: SubscribeStompFrame(destination: destination, destinationId: id))
                            }

                            subscriptionCounter[destination] = currentCounter + 1

                            subscriptionMutex.signal()

                            sub.onNext(messagePublisher)
                        } catch is CancellationError {

                        }
                    }

                    return Disposables.create { [self] in
                        t.cancel()

                        Task {
                            await subscriptionMutex.wait() //Will not get cancelled anyway

                            let currentCounter = subscriptionCounter[destination] ?? 0
                            if currentCounter <= 1 { //Actually, only >1 should be possible
                                //This is the last subscriber
                                print("Unsub from " + destination)
                                swiftStomp.sendFrame(frame: UnsubscribeStompFrame(destination: destination))
                            }
                            subscriptionCounter[destination] = currentCounter - 1

                            subscriptionMutex.signal()
                        }
                    }
                }
                .switchLatest()
                .filter { (message: StompMessage) in
                    message.destination == destination
                }
                .map { [self] message in
                    do {
                        return try jsonProvider.decoder.decode(type, from: Data(message.text.utf8))
                    } catch {
                        print(message.destination)
                        print(message.text)
                        print(error)
                        print(error.localizedDescription)
                        return try jsonProvider.decoder.decode(type, from: Data(message.text.utf8))
                    }
                }
                .catch { error in
                    Observable.empty()
                }
    }

//    func onConnect(swiftStomp: SwiftStomp, connectType: StompConnectType) {

//        switch connectType {
//        case .toSocketEndpoint:
//            ()
//        case .toStomp:
//            //Start heartbeat
//            pingTask = Task {
//                while true {
//                    do {
//                        try await Task.sleep(nanoseconds: UInt64(1e+10))
//                        swiftStomp.ping(data: Data("\n".utf8))
//                    } catch {
//                        break
//                    }
//                }
//            }
//        }
//    }

//    func onDisconnect(swiftStomp: SwiftStomp, disconnectType: StompDisconnectType) {
//        print("Disconnect")
//        pingTask?.cancel()
//    }
//
//    func onReceipt(swiftStomp: SwiftStomp, receiptId: String) {
//        swiftStomp.ping(data: Data("\n".utf8))
//
//        print("receipt")
//    }
//
//    func onError(swiftStomp: SwiftStomp, briefDescription: String, fullDescription: String?, receiptId: String?, type: StompErrorType) {
//        print("Error: " + briefDescription)
//        print("Full " + (fullDescription ?? ""))
//    }
//
//    func onSocketEvent(eventName: String, description: String) {
//        print("Socket event: " + eventName + "; " + description)
//    }
    func clientSendFrame(result: Swift.Result<(), Error>) {
//        print("send frame")
    }

    func handleWebSocketResponse(result: Swift.Result<URLSessionWebSocketTask.Message, Error>) {
//        print("response: ")
    }

    func handleWebSocketDisconnect(session: URLSession, webSocketTask: URLSessionWebSocketTask, closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("disconnect")
        if let r = reason {
            print(String(data: r, encoding: .utf8))
        }
        connectionStatus.onNext(.disconnected)
    }
}

fileprivate struct StompMessage {
    let destination: String
    let text: String
}

enum ConnectionStatus {
    case connecting
    case connected
    case disconnected
}