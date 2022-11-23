import Foundation
import Factory

public extension Container {
    static let jsonProvider = Factory<JsonProvider> {
        JsonProvider()
    }
    
    static let courseRegistrationService = Factory<CourseRegistrationService>(scope: .singleton) {
        CourseRegistrationServiceImpl(jsonProvider: jsonProvider(), networkStatusProvider: networkStatusProvider())
    }
    
    static let courseService = Factory<CourseService>(scope: .singleton) {
        CourseServiceImpl(jsonProvider: jsonProvider())
    }
    
    static let dashboardService = Factory<DashboardService> {
        DashboardServiceImpl(jsonProvider: jsonProvider())
    }
    
    static let loginService = Factory<LoginService> {
        LoginServiceImpl(jsonProvider: jsonProvider())
    }

    static let serverDataService = Factory<ServerDataService> {
        ServerDataServiceImpl(jsonProvider: jsonProvider(), networkStatusProvider: networkStatusProvider())
    }
}
