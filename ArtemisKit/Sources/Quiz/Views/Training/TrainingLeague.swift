import SwiftUI

struct TrainingLeague {
    let index: Int
    let lowerBound: Int
    let upperBound: Int?
    var name: String { TrainingCopy.text("league.name.\(index)") }
    var threshold: String {
        if let upperBound { return String(format: TrainingCopy.text("league.threshold"), lowerBound, upperBound - 1) }
        return String(format: TrainingCopy.text("league.above"), lowerBound)
    }
    static let all = (1...5).compactMap { TrainingLeague(selectedLeague: $0) }.reversed()
    init?(selectedLeague: Int?) {
        guard let selectedLeague, (1...5).contains(selectedLeague) else { return nil }
        index = selectedLeague
        let thresholds = [500, 300, 150, 50, 0]
        lowerBound = thresholds[selectedLeague - 1]
        upperBound = selectedLeague == 1 ? nil : thresholds[selectedLeague - 2]
    }
}

struct TrainingLeagueInfoView: View {
    var body: some View {
        List {
            Section(TrainingCopy.text("league.how")) { Text(TrainingCopy.text("league.how.info")) }
            Section(TrainingCopy.text("league.scoring")) {
                Text(TrainingCopy.text("league.scoring.info"))
                ForEach(Array(TrainingLeague.all), id: \.index) { league in
                    LabeledContent(league.name, value: league.threshold)
                }
                Text(TrainingCopy.text("league.repetition.info"))
            }
        }.navigationTitle(TrainingCopy.text("league.info")).navigationBarTitleDisplayMode(.inline)
    }
}
