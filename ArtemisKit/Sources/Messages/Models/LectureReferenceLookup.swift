import Common
import Foundation
import Navigation
import SharedModels
import SwiftUI

/// Owns one link lookup and its native Retry/Open lectures recovery actions.
@MainActor
@Observable
final class LectureReferenceLookup {
    enum Failure: Equatable {
        case network, missing
        var message: String {
            switch self {
            case .network: "Lecture units could not be loaded. Retry, or open the course's lectures."
            case .missing: "This lecture unit or slide is no longer available. Retry, or open the course's lectures."
            }
        }
    }
    private enum Request { case unit(Int64), slide(Int?, Int64?, Int?) }
    var failure: Failure?
    private(set) var loading = false
    private let coursePath: CoursePath
    private let loader: () async -> DataState<[Lecture]>
    private let navigate: (LecturePath) -> Void
    private let openLectures: () -> Void
    private let isCurrent: () -> Bool
    private var request: Request?
    private var generation = UUID()

    init(coursePath: CoursePath, loader: @escaping () async -> DataState<[Lecture]>,
         navigate: @escaping (LecturePath) -> Void, openLectures: @escaping () -> Void,
         isCurrent: @escaping () -> Bool) {
        self.coursePath = coursePath; self.loader = loader; self.navigate = navigate
        self.openLectures = openLectures; self.isCurrent = isCurrent
    }

    func openUnit(_ id: Int64) async { await load(.unit(id)) }
    func openSlide(id: Int?, unit: Int64?, number: Int?) async { await load(.slide(id, unit, number)) }
    func retry() async { if let request { await load(request) } }
    func showLectures() { cancel(); failure = nil; openLectures() }
    func cancel() { generation = UUID(); loading = false }

    private func load(_ request: Request) async {
        self.request = request
        let attempt = UUID(); generation = attempt
        failure = nil; loading = true
        guard isCurrent() else { loading = false; return }
        let result = await loader()
        guard generation == attempt else { return }
        loading = false
        guard isCurrent() else { return }
        guard case .done(let lectures) = result else { failure = .network; return }
        switch request {
        case .unit(let id):
            if let lecture = lectures.first(where: { $0.lectureUnits?.contains(where: { $0.id == id }) == true }) {
                navigate(LecturePath(id: lecture.id, coursePath: coursePath, target: .init(unitId: id)))
            } else { failure = .missing }
        case let .slide(id, unit, number):
            if let resolved = LectureSlideReference.resolve(slideId: id, unitId: unit, number: number, lectures: lectures) {
                navigate(LecturePath(id: resolved.lecture.id, coursePath: coursePath, target: resolved.target))
            } else { failure = .missing }
        }
    }
}
