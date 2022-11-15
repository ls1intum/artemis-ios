import Foundation
import SwiftStomp
import RxSwift
import Semaphore

class ReactiveSwiftStomp: SwiftStompDelegate {

    private let swiftStomp: SwiftStomp

    private let subscriptionMutex = AsyncSemaphore(value: 1)

    //Accesses must be guarded by the mutex to guarantee thread safety
    private var subscriptionCounter: [String: Int] = [:]

    private var pingTask: Task<Void, Never>? = nil

    init(swiftStomp: SwiftStomp, jsonProvider: JsonProvider) {
        self.swiftStomp = swiftStomp
        self.jsonProvider = jsonProvider

        swiftStomp.delegate = self
        swiftStomp.autoReconnect = true
    }

    private let jsonProvider: JsonProvider

    private var messagePublisher = PublishSubject<StompMessage>()

    func connect() {
        swiftStomp.enableLogging = true
        swiftStomp.connect(acceptVersion: "1.2", autoReconnect: true)
    }

    func disconnect() {
        swiftStomp.autoReconnect = false
        swiftStomp.disconnect(force: true)
    }

    func onMessageReceived(swiftStomp: SwiftStomp, message: Any?, messageId: String, destination: String, headers: [String: String]) {
        swiftStomp.ping(data: Data("\n".utf8))
        if let message = message as? String {
            let stompMessage = StompMessage(destination: destination, data: Data(message.utf8))

            messagePublisher.onNext(stompMessage)
        } else if let message = message as? Data {
            messagePublisher.onNext(StompMessage(destination: destination, data: message))
        }
    }

    func subscribe<T>(destination: String, type: T.Type) -> Observable<T> where T: Decodable {
        messagePublisher
                .do(
                        onSubscribe: { [self] in
                            Task {
                                //Guard the access using a mutex.
                                try await subscriptionMutex.waitUnlessCancelled()
                                let currentCounter = subscriptionCounter[destination] ?? 0

                                //Only subscribe if the destination does not have a subscriber yet.
                                if currentCounter == 0 {
                                    swiftStomp.subscribe(to: destination, mode: .client)
                                }

                                subscriptionCounter[destination] = currentCounter + 1

                                subscriptionMutex.signal()
                            }
                        }
                )
                .filter { message in
                    message.destination == destination
                }
                .map { [self] message in
                    try! jsonProvider.decoder.decode(type, from: message.data)
                }
                .do(
                        onCompleted: { [self] in
                            Task {
                                await subscriptionMutex.wait() //Will not get cancelled anyway

                                let currentCounter = subscriptionCounter[destination] ?? 0
                                if currentCounter <= 1 { //Actually, only >1 should be possible
                                    //This is the last subscriber
                                    swiftStomp.unsubscribe(from: destination)
                                }
                                subscriptionCounter[destination] = currentCounter - 1

                                subscriptionMutex.signal()
                            }
                        }
                )
    }

    func onConnect(swiftStomp: SwiftStomp, connectType: StompConnectType) {
        switch connectType {
        case .toSocketEndpoint:
            ()
        case .toStomp:
            //Start heartbeat
            pingTask = Task {
                while true {
                    do {
                        try await Task.sleep(nanoseconds: UInt64(1e+10))
                        swiftStomp.ping(data: Data("\n".utf8))
                    } catch {
                        break
                    }
                }
            }
        }
    }

    func onDisconnect(swiftStomp: SwiftStomp, disconnectType: StompDisconnectType) {
        print("Disconnect")
        pingTask?.cancel()
    }

    func onReceipt(swiftStomp: SwiftStomp, receiptId: String) {
        swiftStomp.ping(data: Data("\n".utf8))

        print("receipt")
    }

    func onError(swiftStomp: SwiftStomp, briefDescription: String, fullDescription: String?, receiptId: String?, type: StompErrorType) {
        print("Error: " + briefDescription)
        print("Full " + (fullDescription ?? ""))
    }

    func onSocketEvent(eventName: String, description: String) {
        print("Socket event: " + eventName + "; " + description)
    }
}

fileprivate struct StompMessage {
    let destination: String
    let data: Data
}