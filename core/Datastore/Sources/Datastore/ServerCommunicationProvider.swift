import Foundation
import RxSwift

public protocol ServerCommunicationProvider {

    /**
     * Emits the currently selected server. Emits again, when the user changes their artemis instance in the settings.
     */
    var serverUrl: Observable<String> { get }

    /**
     * Just returns the domain of the serverUrl.
     */
    var host: Observable<String> { get }
}
