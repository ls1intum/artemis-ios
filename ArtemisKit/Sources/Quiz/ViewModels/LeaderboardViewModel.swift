//
//  LeaderboardViewModel.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 06.06.26.
//

import APIClient
import Common
import Foundation
import SharedModels

@Observable
class LeaderboardViewModel {
    let courseId: Int

    var leaderboardData: DataState<DTO.LeaderboardWithCurrentUserEntry> = .loading

    init(courseId: Int) {
        self.courseId = courseId
    }

    func loadLeaderboard() async {
        leaderboardData = await APIClient().call { client in
            try await client.getQuizTrainingLeaderboard(path: .init(courseId: Int64(courseId)))
                .ok.body.json
        }
    }
}
