//
//  LeaderboardScoreCard.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 06.06.26.
//

import SharedModels
import SwiftUI

struct LeaderboardScoreCard: View {
    let entry: DTO.LeaderboardEntry

    let leaguePoints = [
        0..<50, 50..<150, 150..<300, 300..<500, 500..<Int.max
    ]
    let leagueNames = [
        "Bronze", "Silver", "Gold", "Diamond", "Master"
    ]

    var body: some View {
        if let league = entry.selectedLeague.map({ leaguePoints.count - Int($0) }),
           league < leaguePoints.count && league >= 0 {
            Section(R.string.localizable.league()) {
                HStack {
                    Image(leagueNames[league].lowercased(), bundle: .module)
                        .resizable()
                        .frame(width: .mediumImage, height: .mediumImage)

                    VStack {
                        Text("\(leagueNames[league]) league")
                        let pointsRange = leaguePoints[league]
                        Text("\(entry.score ?? 0) / \(pointsRange.upperBound) points")
                        ProgressView(value: Float(Int(entry.score ?? 0) - pointsRange.lowerBound),
                                     total: Float(pointsRange.upperBound - pointsRange.lowerBound))
                    }
                }
            }
        }
    }
}
