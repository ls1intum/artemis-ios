import Foundation
import Model
import Data
import Common

/**
 * Service where you can make requests about the Artemis dashboard.
 */
protocol DashboardService {

    /**
     * Load the dashboard from the specified server using the specified authentication data.
     */
    func loadCourses() async -> DataState<[Course]>
}

enum DashboardServiceFactory {
    
    static let shared: DashboardService = DashboardServiceImpl()
    
}
