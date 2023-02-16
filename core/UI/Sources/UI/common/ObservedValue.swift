import Foundation
import SwiftUI
import Combine

public class ObservedValue<T>: ObservableObject {
    @Published public var latestValue: T

    public init(publisher: AnyPublisher<T, Never>, initialValue: T) {
        latestValue = initialValue

        publisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$latestValue)
    }
}
