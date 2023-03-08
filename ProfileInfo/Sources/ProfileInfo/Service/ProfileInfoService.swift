//
//  File.swift
//
//
//  Created by Sven Andabaka on 06.02.23.
//

import Foundation
import Common

public protocol ProfileInfoService {
    /**
     * Perform a getProfileInfo request to the server. ProfileInfo contains all information on the currentty deployed Artemis version.
     */
    func getProfileInfo() async -> DataState<ProfileInfo>
}

public enum ProfileInfoServiceFactory {
    public static let shared: ProfileInfoService = ProfileInfoServiceImpl()
}
