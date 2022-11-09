import Foundation
import Combine
import RxSwift

/**
 * Adapted from: https://www.swiftbysundell.com/articles/creating-combine-compatible-versions-of-async-await-apis/
 */
extension AsyncSequence {
    func publisher() -> AnyPublisher<Element, Error> {
        AnyPublisher<Element, Error>.create { subscription in
            let task = Task {
                do {
                    for try await value in self {
                        subscription.send(value)
                    }

                    subscription.send(completion: .finished)
                } catch {
                    subscription.send(completion: .failure(error))
                }
            }

            return AnyCancellable {
                task.cancel()
            }
        }
    }
}

extension Observable {
    func transformLatest<T>(_ transform: @escaping (AnyObserver<T>, Element) async -> ()) -> Observable<T> {
        self
                .map { output in
                    Observable<T>.create { subscription in
                        let task = Task {
                            await transform(subscription, output)
                        }

                        return Disposables.create {
                            task.cancel()
                        }
                    }
                }
                .switchLatest()
    }
}

extension AnyObserver {

    /**
     * Sends all elements received by the publisher to the original caller.
     */
    func sendAll(publisher: Observable<Element>) async throws {
        for try await v in publisher.values {
            onNext(v)
        }
    }
}