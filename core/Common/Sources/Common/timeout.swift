import Foundation

/**
 Waits at most the in timeout specified time interval for the perform action to complete. Else, a cancellation error is thrown.
 */
//Adapted from: https://gist.github.com/swhitty/9be89dfe97dbb55c6ef0f916273bbb97
public func withTimeout<T>(timeout: TimeInterval, perform: @Sendable @escaping () async throws -> T) async throws -> T {
    try await withTimeoutImpl(timeout: timeout, perform: perform, onTimeout: { throw CancellationError() })
}

/**
 * Wait at most the specified time interval for perform to complete. If perform does not return in time, null is returned instead.
 */
public func withTimeoutOrNull<T>(timeout: TimeInterval, perform: @Sendable @escaping () async throws -> T?) async throws -> T? {
    try await withTimeoutImpl(timeout: timeout, perform: perform, onTimeout: { nil })
}

private func withTimeoutImpl<T>(timeout: TimeInterval, perform: @Sendable @escaping () async throws -> T, onTimeout: () throws -> T) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask(operation: perform)
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
            throw TimeoutError()
        }

        guard let response = try await group.next() else {
            return try onTimeout()
        }

        group.cancelAll()

        return response
    }
}

public struct TimeoutError: Error {

}
