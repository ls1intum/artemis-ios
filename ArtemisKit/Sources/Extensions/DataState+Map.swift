//
//  DataState+Map.swift
//
//
//  Created by Nityananda Zbil on 05.03.24.
//

import Common

public extension DataState {
    func map<U>(_ transform: (T) -> U) -> DataState<U> {
        .init(toOptionalResult()?.map(transform))
    }

    func flatMap<U>(_ transform: (T) -> Swift.Result<U, UserFacingError>) -> DataState<U> {
        .init(toOptionalResult()?.flatMap(transform))
    }
}

private extension DataState {
    init(_ optionalResult: Swift.Result<T, UserFacingError>?) {
        switch optionalResult {
        case let .success(success):
            self = .done(response: success)
        case let .failure(failure):
            self = .failure(error: failure)
        case nil:
            self = .loading
        }
    }

    func toOptionalResult() -> Swift.Result<T, UserFacingError>? {
        switch self {
        case let .done(response: success):
            return .success(success)
        case let .failure(error: failure):
            return .failure(failure)
        case .loading:
            return nil
        }
    }
}
