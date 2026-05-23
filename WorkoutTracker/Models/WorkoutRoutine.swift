import Foundation
import SwiftData

@Model
final class WorkoutRoutine {
    var id: UUID
    var name: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \ExerciseTarget.routine)
    var exercises: [ExerciseTarget]

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.exercises = []
    }
}
