import Foundation
import SwiftData

@Model
final class ExerciseTarget {
    var id: UUID
    var name: String
    var order: Int

    @Relationship(deleteRule: .cascade, inverse: \SetTarget.exercise)
    var sets: [SetTarget]

    var routine: WorkoutRoutine?

    init(name: String, order: Int) {
        self.id = UUID()
        self.name = name
        self.order = order
        self.sets = []
    }
}
