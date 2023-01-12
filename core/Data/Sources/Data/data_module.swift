import Foundation
import Factory

public extension Container {
    static let jsonProvider = Factory<JsonProvider> {
        JsonProvider()
    }
    
    static let serverDataService = Factory<ServerDataService> {
        ServerDataServiceImpl(jsonProvider: jsonProvider(), networkStatusProvider: networkStatusProvider())
    }
}
