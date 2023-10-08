import Foundation

struct ModelingExerciseHandler: Deeplink {

    let courseId: Int
    let exerciseId: Int
    let participationId: Int

    static func build(from url: URL) -> ModelingExerciseHandler? {
        guard let indexOfCourseId = url.pathComponents.firstIndex(where: { $0 == "courses" }),
              url.pathComponents.count > indexOfCourseId + 1,
              let courseId = Int(url.pathComponents[indexOfCourseId + 1]),
              let indexOfExerciseId = url.pathComponents.firstIndex(where: { $0 == "modeling-exercises" }),
              url.pathComponents.count > indexOfExerciseId + 1,
              let exerciseId = Int(url.pathComponents[indexOfExerciseId + 1]),
              let indexOfModelingExerciseId = url.pathComponents.firstIndex(where: { $0 == "participate" }),
              url.pathComponents.count > indexOfModelingExerciseId + 1,
              let modelingExerciseId = Int(url.pathComponents[indexOfModelingExerciseId + 1]),
              let urlComponent = URLComponents(string: url.absoluteString),
              !(urlComponent.queryItems?.contains(where: { $0.name == "postId" }) ?? false) else { return nil }

        return ModelingExerciseHandler(courseId: courseId, exerciseId: exerciseId, participationId: modelingExerciseId)
    }

    func handle(with navigationController: NavigationController) {
        Task(priority: .userInitiated) {
            await navigationController.goToExercise(courseId: courseId, exerciseId: exerciseId)
        }
    }
}
