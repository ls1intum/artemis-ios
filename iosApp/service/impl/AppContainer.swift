import Factory

/**
 * Dependency injection container for this app.
 */
extension Container {
    static let serverCommunicationProvider = Factory<ServerCommunicationProvider> {
        ServerCommunicationProviderImpl()
    }

    static let jsonProvider = Factory<JsonProvider> {
        JsonProvider()
    }

    static let accountService = Factory<AccountService>(scope: .singleton) {
        AccountServiceImpl(serverCommunicationProvider: serverCommunicationProvider(), jsonProvider: JsonProvider(), networkStatusProvider: networkStatusProvider())
    }

    static let dashboardService = Factory<DashboardService> {
        DashboardServiceImpl(jsonProvider: jsonProvider())
    }

    static let networkStatusProvider = Factory<NetworkStatusProvider>(scope: .singleton) {
        NetworkStatusProviderImpl()
    }

    static let courseRegistrationService = Factory<CourseRegistrationService>(scope: .singleton) {
        CourseRegistrationServiceImpl(jsonProvider: jsonProvider())
    }
}