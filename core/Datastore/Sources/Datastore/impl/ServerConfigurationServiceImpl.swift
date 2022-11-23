import Foundation
import RxSwift

/**
 * Provides data about which instance of artemis is communicated with.
 */
class ServerConfigurationServiceImpl: ServerConfigurationService {

    /**
     * The currently selected server.
     */
    var serverUrl: Observable<String> = Observable.of("https://artemis.ase.in.tum.de/")
    var host: Observable<String> = Observable.of("artemis.ase.in.tum.de")
}
