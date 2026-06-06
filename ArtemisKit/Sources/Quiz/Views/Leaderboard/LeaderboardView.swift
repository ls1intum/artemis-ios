//
//  LeaderboardView.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 06.06.26.
//

import DesignLibrary
import Extensions
import SharedModels
import SwiftUI

struct LeaderboardView: View {
    @State private var viewModel: LeaderboardViewModel

    init(courseId: Int) {
        self._viewModel = State(initialValue: LeaderboardViewModel(courseId: courseId))
    }

    var body: some View {
        DataStateView(data: $viewModel.leaderboardData) {
            await viewModel.loadLeaderboard()
        } content: { leaderboard in
            LeaderboardScoreCard(entry: leaderboard.currentUserEntry)
            CurrentUserEntry(entry: leaderboard.currentUserEntry)

            Section(R.string.localizable.leaderboard()) {
                ForEach(leaderboard.leaderboardEntries, id: \.userId) { entry in
                    LeaderboardEntryView(entry: entry)
                }
            }
        }
        .task(id: "loadLeaderboard") {
            if case .done = viewModel.leaderboardData {
                return
            }
            await viewModel.loadLeaderboard()
        }
    }
}

private struct CurrentUserEntry: View {
    let entry: DTO.LeaderboardEntry

    init(entry: DTO.LeaderboardEntry) {
        var newEntry = entry
        newEntry.rank = (newEntry.rank ?? 0) + 1
        self.entry = newEntry
    }

    var body: some View {
        Section(R.string.localizable.yourRanking()) {
            LeaderboardEntryView(entry: entry)
        }
    }
}

private struct LeaderboardEntryView: View {
    let entry: DTO.LeaderboardEntry

    var body: some View {
        HStack(spacing: .l) {
            if let rank = entry.rank {
                Text("#\(rank)")
                    .font(.largeTitle.bold().monospacedDigit())
            }

            ArtemisAsyncImage(imageURL: entry.imagePath) {}
                .frame(width: .xl, height: .xl)
                .clipShape(.rect(cornerRadius: .m))

            VStack(alignment: .leading) {
                Text(entry.userName)
                    .lineLimit(1)
                Text("Score: \(entry.score ?? 0)")
            }
        }
    }
}

extension DTO.LeaderboardEntry: WithImage {}
