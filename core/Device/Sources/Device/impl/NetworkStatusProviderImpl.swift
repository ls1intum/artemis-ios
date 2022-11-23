import Foundation
import RxSwift
import Reachability

class NetworkStatusProviderImpl: NetworkStatusProvider {

    /**
     * Use https://github.com/ashleymills/Reachability.swift to gather information about the internet access of this device.
     */
    var currentNetworkStatus: Observable<NetworkStatus> = Observable.create { subscriber in
        do {
            let reachability: Reachability = try Reachability()

            reachability.whenReachable = { r in
                subscriber.onNext(NetworkStatus.internet)
            }

            reachability.whenUnreachable = { r in
                subscriber.onNext(NetworkStatus.unavailable)
            }

            try! reachability.startNotifier()

            return Disposables.create {
                reachability.stopNotifier()
            }
        } catch {
            //Apparently we cannot gather information using reachability. Therefore, we just say the device always has internet.
            subscriber.onNext(NetworkStatus.internet)

            return Disposables.create()
        }
    }
}
