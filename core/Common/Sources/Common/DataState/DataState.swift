import Foundation

/**
 * The data state of the request.
 */
public enum DataState<T> {
    /**
     * Currently loading.
     */
    case loading

    case failure(error: UserFacingError)

    case done(response: T)

    public var value: T? {
        switch self {
        case .done(let value):
            return value
        default:
            return nil
        }
    }
}
