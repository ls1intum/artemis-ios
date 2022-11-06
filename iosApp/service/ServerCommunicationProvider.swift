import Foundation
import Combine

protocol ServerCommunicationProvider {

    /**
     * Emits the currently selected server. Emits again, when the user changes their artemis instance in the settings.
     */
    var serverUrl: AnyPublisher<String, Never> { get }

    /**
     * Just returns the domain of the serverUrl.
     */
    var host: AnyPublisher<String, Never> { get }
}
