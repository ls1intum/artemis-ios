import Foundation

/**
 * The data state of the request.
 */
public enum DataState<T> {
    
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
    
    public var value: T? {
        switch self {
        case .done(let value):
            return value
        default:
            return nil
        }
    }
}
