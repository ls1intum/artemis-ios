import Foundation
import RxSwift
import Combine

/**
 * The data state of the request.
 */
enum DataState<T> {

    /**
     * Waiting until a valid internet connection is available again.
     */
    case suspended(error: Error?)

    /**
     * Currently loading.
     */
    case loading

    case failure(error: Error)

    case done(response: T)

    func bind<K>(op: (T) -> K) -> DataState<K> {
        switch self {
        case .suspended(error: let exception): return DataState<K>.suspended(error: exception)
        case .loading: return DataState<K>.loading
        case .failure(error: let exception): return DataState<K>.failure(error: exception)
        case .done(response: let response): return DataState<K>.done(response: op(response))
        }
    }

    func orElse(other: T) -> T {
        switch self {
        case .done(response: let response): return response
        default: return other
        }
    }

    func orThrow() throws -> T {
        switch self {
        case .done(response: let response): return response
        default: throw NSError()
        }
    }

    func isSuccess() -> Bool {
        switch self {
        case .done(response: _): return true
        default: return false
        }
    }
}

func retryOnInternet<T>(
        connectivity: Observable<NetworkStatus>,
        baseBackoffMillis: UInt64 = 2000,
        perform: @escaping () async -> NetworkResponse<T>
) -> Observable<DataState<T>> {
    connectivity
            .transformLatest { subscription, networkStatus in
                switch networkStatus {
                case .internet:
                    //Fetch data with exponential backoff
                    var currentBackoff = baseBackoffMillis

                    while true {
                        subscription.onNext(DataState<T>.loading)

                        let response: NetworkResponse<T> = await perform()
                        switch response {
                        case .response(let data):
                            subscription.onNext(DataState<T>.done(response: data))
                            return
                        case .failure(let error):
                            subscription.onNext(DataState<T>.failure(error: error))
                        }

                        //Perform exponential backoff
                        do {
                            try await Task.sleep(nanoseconds: currentBackoff * NSEC_PER_MSEC)
                        } catch {
                             return
                        }
                        currentBackoff *= 2
                    }
                case .unavailable:
                    subscription.onNext(DataState<T>.suspended(error: nil))
                }
            }
}

extension Publisher {
    func replaceWithDataStateError<T>() -> AnyPublisher<Output, Never> where Output == DataState<T> {
        `catch` { failure in Just(.failure(error: failure)) }
                .eraseToAnyPublisher()
    }
}