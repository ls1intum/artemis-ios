import Foundation
import Model
import Data
import APIClient
import Common

/**
 * DashboardService implementation that requests the dashboard from the Artemis server.
 */
class DashboardServiceImpl: DashboardService {
    
    let client = APIClient()
    
    struct GetCoursesRequest: APIRequest {
        typealias Response = [Course]
        
        var method: HTTPMethod {
            return .get
        }
        
        var resourceName: String {
            return "api/courses/for-dashboard"
        }
    }
    
    func loadCourses() async -> DataState<[Course]> {
        let result = await client.send(GetCoursesRequest())
        
        switch result {
        case .success((let response, _)):
            return .done(response: response)
        case .failure(let error):
            return .failure(error: error)
        }
    }
}
