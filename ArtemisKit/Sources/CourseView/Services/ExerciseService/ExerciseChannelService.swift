//
//  ExerciseChannelService.swift
//  
//
//  Created by Anian Schleyer on 18.08.24.
//

import Foundation
import Common
import SharedModels

protocol ExerciseChannelService {
    func getAssociatedChannel(for exerciseId: Int, in courseId: Int) async -> DataState<Channel>
}

enum ExerciseChannelServiceFactory {
    static let shared: ExerciseChannelService = ExerciseChannelServiceImpl()
}
