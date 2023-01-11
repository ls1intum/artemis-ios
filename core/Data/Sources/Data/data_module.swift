import Foundation
import Factory

public extension Container {
    static let jsonProvider = Factory<JsonProvider> {
        JsonProvider()
    }
    
    static let courseService = Factory<CourseService>(scope: .singleton) {
        CourseServiceImpl(jsonProvider: jsonProvider())
    }
    
    static let dashboardService = Factory<DashboardService> {
        DashboardServiceImpl(jsonProvider: jsonProvider())
    }

    static let serverDataService = Factory<ServerDataService> {
        ServerDataServiceImpl(jsonProvider: jsonProvider(), networkStatusProvider: networkStatusProvider())
    }
}
