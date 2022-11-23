import Foundation
import Combine
import RxSwift

public extension Observable {
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

public extension AnyObserver {

    /**
     * Sends all elements received by the publisher to the original caller.
     */
    func sendAll(publisher: Observable<Element>) async throws {
        for try await v in publisher.values {
            onNext(v)
        }
    }
}
