import Foundation
import RxSwift

/**
 * Service that provides the current connectivity status of this device.
 */
public protocol NetworkStatusProvider {

    /**
     * Emits every time when the connectivity of this device to the internet changes.
     */
    var currentNetworkStatus: Observable<NetworkStatus> { get }
}

public enum NetworkStatus {
    case internet
    case unavailable
}
