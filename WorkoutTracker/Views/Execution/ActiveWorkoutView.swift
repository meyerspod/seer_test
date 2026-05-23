import SwiftUI
import SwiftData

// MARK: - ActiveWorkoutView

struct ActiveWorkoutView: View {
    @Bindable var routine: WorkoutRoutine
    @Environment(\.dismiss) private var dismiss

    private var sortedExercises: [ExerciseTarget] {
        routine.exercises.sorted { $0.order < $1.order }
    }

    private var allSets: [SetTarget] {
        sortedExercises.flatMap { $0.sets.sorted { $0.index < $1.index } }
    }

    private var completedCount: Int { allSets.filter(\.isCompleted).count }
    private var totalCount: Int { allSets.count }
    private var allDone: Bool { totalCount > 0 && completedCount == totalCount }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                progressHeader
                    .padding(.horizontal)
                    .padding(.top, 8)

                ForEach(sortedExercises) { exercise in
                    ActiveExerciseSection(exercise: exercise)
                }

                finishButton
                    .padding(.horizontal)
                    .padding(.bottom, 32)
            }
        }
        .navigationTitle(routine.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { resetActuals() }
    }

    // MARK: Subviews

    private var progressHeader: some View {
        VStack(spacing: 6) {
            ProgressView(value: Double(completedCount), total: Double(max(totalCount, 1)))
                .tint(allDone ? .green : .blue)
                .animation(.easeInOut, value: completedCount)
            Text("\(completedCount) / \(totalCount) sets complete")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var finishButton: some View {
        Button {
            dismiss()
        } label: {
            Label("Finish Workout", systemImage: "flag.checkered")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(allDone ? Color.green : Color(.systemGray4))
                .foregroundStyle(.white)
                .cornerRadius(16)
                .animation(.easeInOut, value: allDone)
        }
    }

    // MARK: Logic

    private func resetActuals() {
        for exercise in routine.exercises {
            for set in exercise.sets {
                set.actualReps = nil
                set.actualWeight = nil
                set.isCompleted = false
            }
        }
    }
}

// MARK: - ActiveExerciseSection

struct ActiveExerciseSection: View {
    @Bindable var exercise: ExerciseTarget

    private var sortedSets: [SetTarget] {
        exercise.sets.sorted { $0.index < $1.index }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(exercise.name)
                .font(.title3.weight(.bold))
                .padding(.horizontal, 16)

            VStack(spacing: 8) {
                ForEach(sortedSets) { set in
                    ActiveSetRow(set: set)
                }
            }
            .padding(.horizontal, 12)
        }
        .padding(.vertical, 14)
        .background(Color(.systemGray6))
        .cornerRadius(18)
        .padding(.horizontal)
    }
}

// MARK: - ActiveSetRow

struct ActiveSetRow: View {
    @Bindable var set: SetTarget
    @State private var showingCalculator = false

    private var displayReps: Int   { set.actualReps   ?? set.targetReps   }
    private var displayWeight: Double { set.actualWeight ?? set.targetWeight }

    var body: some View {
        HStack(spacing: 12) {
            completionToggle

            setLabel

            Spacer()

            repsControl

            weightButton
        }
        .padding(12)
        .background(rowBackground)
        .cornerRadius(14)
        .sheet(isPresented: $showingCalculator) {
            PlateCalculatorSheet(
                targetWeight: set.targetWeight,
                confirmedWeight: Binding(
                    get: { set.actualWeight ?? set.targetWeight },
                    set: { set.actualWeight = $0 }
                ),
                isPresented: $showingCalculator
            )
        }
    }

    // MARK: Row pieces

    private var completionToggle: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                set.isCompleted.toggle()
                if set.isCompleted {
                    if set.actualReps   == nil { set.actualReps   = set.targetReps   }
                    if set.actualWeight == nil { set.actualWeight = set.targetWeight }
                }
            }
        } label: {
            Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundStyle(set.isCompleted ? .green : Color(.systemGray3))
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.plain)
    }

    private var setLabel: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Set \(set.index + 1)")
                .font(.subheadline.weight(.semibold))
            Text("Target: \(set.targetReps) × \(formatted(set.targetWeight)) lbs")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    private var repsControl: some View {
        VStack(spacing: 3) {
            Text("REPS")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.tertiary)
            HStack(spacing: 10) {
                Button {
                    if displayReps > 0 { set.actualReps = displayReps - 1 }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(displayReps > 0 ? Color.blue : Color(.systemGray4))
                }
                .buttonStyle(.plain)

                Text("\(displayReps)")
                    .font(.title3.monospacedDigit().weight(.semibold))
                    .frame(minWidth: 26, alignment: .center)

                Button {
                    set.actualReps = displayReps + 1
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var weightButton: some View {
        Button { showingCalculator = true } label: {
            VStack(spacing: 2) {
                Text("WEIGHT")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.tertiary)
                Text(formatted(displayWeight))
                    .font(.title3.monospacedDigit().weight(.semibold))
                    .foregroundStyle(set.actualWeight != nil ? .primary : .secondary)
                Text("lbs")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(.systemGray5))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }

    private var rowBackground: Color {
        set.isCompleted ? Color.green.opacity(0.12) : Color(.systemGray5)
    }

    private func formatted(_ w: Double) -> String {
        w.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(w)) : String(format: "%.1f", w)
    }
}
