import Foundation
import Factory

public extension Container {
    static let networkStatusProvider = Factory<NetworkStatusProvider>(scope: .singleton) {
        NetworkStatusProviderImpl()
    }
}