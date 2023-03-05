//
//  File.swift
//
//
//  Created by Sven Andabaka on 06.02.23.
//

import Foundation
import APIClient
import Common

class ProfileInfoServiceImpl: ProfileInfoService {
    private let client = APIClient()

    struct GetProfileInfoRequest: APIRequest {
        typealias Response = ProfileInfo

        var method: HTTPMethod {
            return .get
        }

        var resourceName: String {
            return "management/info"
        }
    }

    func getProfileInfo() async -> Common.DataState<ProfileInfo> {
        let result = await client.sendRequest(GetProfileInfoRequest())

        switch result {
        case .success((let profileInfo, _)):
            return .done(response: profileInfo)
        case .failure(let error):
            return DataState(error: error)
        }
    }
}
