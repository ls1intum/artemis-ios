//
//  DataState+Map.swift
//
//
//  Created by Nityananda Zbil on 05.03.24.
//

import Common

public extension DataState {
    func map<U>(_ transform: (T) -> U) -> DataState<U> {
        .init(Result(self)?.map(transform))
    }

    func flatMap<U>(_ transform: (T) -> Swift.Result<U, UserFacingError>) -> DataState<U> {
        .init(Result(self)?.flatMap(transform))
    }
}

private extension Swift.Result where Failure == UserFacingError {
    init?(_ state: DataState<Success>) {
        switch state {
        case .loading:
            return nil
        case let .done(response: success):
            self = .success(success)
        case let .failure(error: error):
            self = .failure(error)
        }
    }
}

private extension DataState {
    init(_ result: Swift.Result<T, UserFacingError>?) {
        switch result {
        case let .success(success):
            self = .done(response: success)
        case let .failure(failure):
            self = .failure(error: failure)
        case nil:
            self = .loading
        }
    }
}
