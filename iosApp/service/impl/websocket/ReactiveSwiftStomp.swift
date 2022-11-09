import Foundation
import SwiftStomp
import Combine
import CombineExt
import Semaphore

class ReactiveSwiftStomp: SwiftStompDelegate {

    private let swiftStomp: SwiftStomp

    private let subscriptionMutex = AsyncSemaphore(value: 1)

    //Accesses must be guarded by the mutex to guarantee thread safety
    private var subscriptionCounter: [String: Int] = [:]

    init(swiftStomp: SwiftStomp, jsonProvider: JsonProvider) {
        self.swiftStomp = swiftStomp
        self.jsonProvider = jsonProvider

        swiftStomp.delegate = self
        swiftStomp.autoReconnect = true
    }

    private let jsonProvider: JsonProvider

    private var messagePublisher = PassthroughSubject<StompMessage, Never>()

    func connect() {
        swiftStomp.connect()
    }

    func disconnect() {
        swiftStomp.autoReconnect = false
        swiftStomp.disconnect(force: true)
    }

    func onMessageReceived(swiftStomp: SwiftStomp, message: Any?, messageId: String, destination: String, headers: [String: String]) {
        if let message = message as? String {
            let stompMessage = StompMessage(destination: destination, data: Data(message.utf8))

            messagePublisher.send(stompMessage)
        } else if let message = message as? Data {
            messagePublisher.send(StompMessage(destination: destination, data: message))
        }
    }

    func subscribe<T>(destination: String, type: T.Type) -> AnyPublisher<T, Never> where T: Decodable {
        AnyPublisher.create { [self] subscriber in
            let task = Task {
                //Guard the access using a mutex.
                try await subscriptionMutex.waitUnlessCancelled()
                let currentCounter = subscriptionCounter[destination] ?? 0

                //Only subscribe if the destination does not have a subscriber yet.
                if currentCounter == 0 {
                    swiftStomp.subscribe(to: destination)
                }

                subscriptionCounter[destination] = currentCounter + 1

                subscriptionMutex.signal()

                let topicPublisher: AnyPublisher<T, Never> = messagePublisher
                        .filter { message in
                            message.destination == destination
                        }
                        .map { [self] message in
                            try! jsonProvider.decoder.decode(type, from: message.data)
                        }
                        .eraseToAnyPublisher()

                try await subscriber.sendAll(publisher: topicPublisher)
            }


            return AnyCancellable { [self] in
                task.cancel()

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
        }

    }

    func onConnect(swiftStomp: SwiftStomp, connectType: StompConnectType) {

    }

    func onDisconnect(swiftStomp: SwiftStomp, disconnectType: StompDisconnectType) {

    }

    func onReceipt(swiftStomp: SwiftStomp, receiptId: String) {
        <#code#>
    }

    func onError(swiftStomp: SwiftStomp, briefDescription: String, fullDescription: String?, receiptId: String?, type: StompErrorType) {
        <#code#>
    }

    func onSocketEvent(eventName: String, description: String) {
        <#code#>
    }
}

fileprivate struct StompMessage {
    let destination: String
    let data: Data
}