import Foundation
import SwiftData

@Model
final class SetTarget {
    var id: UUID
    var index: Int
    var targetReps: Int
    var targetWeight: Double
    var actualReps: Int?
    var actualWeight: Double?
    var isCompleted: Bool

    var exercise: ExerciseTarget?

    init(index: Int, targetReps: Int, targetWeight: Double) {
        self.id = UUID()
        self.index = index
        self.targetReps = targetReps
        self.targetWeight = targetWeight
        self.actualReps = nil
        self.actualWeight = nil
        self.isCompleted = false
    }
}
