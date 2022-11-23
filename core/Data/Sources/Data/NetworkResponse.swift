import Foundation

/**
 * Wrapper around network responses. Used to propagate failures correctly.
 */
public enum NetworkResponse<T> {
    case response(data: T)
    case failure(error: Error)

    public func bind<K>(f: (T) -> K) -> NetworkResponse<K> {
        switch self {
        case .response(data: let data): return NetworkResponse<K>.response(data: f(data))
        case .failure(error: let error): return NetworkResponse<K>.failure(error: error)
        }
    }
}

public func performNetworkCall<T>(perform: () async throws -> T) async -> NetworkResponse<T> {
    do {
        return .response(data: try await perform())
    } catch {
        return NetworkResponse<T>.failure(error: error)
    }
}
