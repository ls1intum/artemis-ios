import Foundation
import Model

/**
 * Service where you can make requests about the Artemis dashboard.
 */
public protocol DashboardService {

    /**
     * Load the dashboard from the specified server using the specified authentication data.
     */
    func loadDashboard(authorizationToken: String, serverUrl: String) async -> NetworkResponse<Dashboard>
}
