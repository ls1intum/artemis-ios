import Foundation
import SwiftUI
import SwiftDate

private class WeeklyExercisesExpandedModel: ObservableObject {

    /**
     * Map from the firstDayOfTheWeek
     */
    @Published var isExpanded: [Date?: Bool] = [:]
}

struct ExerciseListView: View {

    let exerciseDataState: DataState<[WeeklyExercises]>
    let onClickExercise: (_ exerciseId: Int) -> Void

    @ObservedObject private var weeklyExercisesExpanded = WeeklyExercisesExpandedModel()

    var body: some View {
        EmptyDataStateView(dataState: exerciseDataState) { weeklyExercises in
            LazyVStack {
                ForEach(weeklyExercises) { (weeklyExercisesEntry: WeeklyExercises) in
                    Section(header: Text("section")) {
                        ForEach(weeklyExercisesEntry.exercises) { exercise in
                            Text("An exercise")
                        }
                    }
                }
            }
        }
    }

    private func areWeeklyExercisesExpanded(dict: [Date?: Bool], weeklyExercises: WeeklyExercises) -> Bool {
        switch weeklyExercises {
        case .BoundToWeek(firstDayOfWeek: let firstDayOfWeek, _, _):
            let daysDiff = Calendar.current.dateComponents([.day], from: firstDayOfWeek, to: Date()).day ?? 0
            let defaultValue = daysDiff < 14
            return dict[firstDayOfWeek] ?? defaultValue
        case .Unbound(_):
            let defaultValue = true
            return dict[nil] ?? defaultValue
        }
    }
}