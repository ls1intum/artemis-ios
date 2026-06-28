//
//  LeagueInfoView.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 20.06.26.
//

import SwiftUI

struct LeagueInfoView: View {
    let leagues: [String]
    let leaguePoints: [Range<Int>]

    var body: some View {
        List {
            Section(R.string.localizable.aboutTraining()) {
                Text(R.string.localizable.aboutTrainingText())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
            }

            Section(R.string.localizable.leaguesAndScoring()) {
                Text(R.string.localizable.leaguesDetail1())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .listRowSeparator(.hidden)

                Grid(horizontalSpacing: .l) {
                    ForEach(leagues.enumerated(), id: \.element) { index, league in
                        GridRow {
                            Image(league.lowercased(), bundle: .module)

                            Text(league)
                                .gridColumnAlignment(.leading)

                            let range = leaguePoints[index]
                            if range.upperBound == Int.max {
                                Text("\(range.lowerBound)+")
                                    .gridColumnAlignment(.leading)
                            } else {
                                Text("\(range.lowerBound) - \(range.upperBound)")
                                    .gridColumnAlignment(.leading)
                            }
                        }
                        .font(.title3)
                    }
                }
                .listRowSeparator(.hidden)

                Text(R.string.localizable.leaguesDetail2())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .listRowSeparator(.hidden)
            }
        }
        .navigationTitle(R.string.localizable.quizTraining())
        .toolbarTitleDisplayMode(.inline)
    }
}
