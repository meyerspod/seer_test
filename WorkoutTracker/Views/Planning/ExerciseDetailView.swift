import SwiftUI
import SwiftData

struct ExerciseDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var exercise: ExerciseTarget

    private var sortedSets: [SetTarget] {
        exercise.sets.sorted { $0.index < $1.index }
    }

    var body: some View {
        List {
            if sortedSets.isEmpty {
                Text("No sets yet. Tap \"Add Set\" to start.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .listRowBackground(Color.clear)
            }

            ForEach(sortedSets) { set in
                SetTargetRow(set: set)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
            .onDelete(perform: deleteSets)

            Button {
                addSet()
            } label: {
                Label("Add Set", systemImage: "plus.circle.fill")
                    .foregroundStyle(.blue)
                    .font(.body.weight(.medium))
            }
            .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.large)
    }

    private func addSet() {
        let defaults = sortedSets.last
        let newSet = SetTarget(
            index: exercise.sets.count,
            targetReps: defaults?.targetReps ?? 8,
            targetWeight: defaults?.targetWeight ?? 135
        )
        exercise.sets.append(newSet)
    }

    private func deleteSets(at offsets: IndexSet) {
        let sorted = sortedSets
        for index in offsets {
            modelContext.delete(sorted[index])
        }
    }
}

struct SetTargetRow: View {
    @Bindable var set: SetTarget

    var body: some View {
        HStack(spacing: 0) {
            Text("Set \(set.index + 1)")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 52, alignment: .leading)

            Spacer()

            CounterControl(label: "REPS", value: $set.targetReps, step: 1, minimum: 1)

            Divider()
                .frame(height: 36)
                .padding(.horizontal, 16)

            WeightControl(label: "LBS", weight: $set.targetWeight, step: 5)
        }
    }
}

struct CounterControl: View {
    let label: String
    @Binding var value: Int
    let step: Int
    let minimum: Int

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.tertiary)
                .kerning(0.5)

            HStack(spacing: 14) {
                Button {
                    if value - step >= minimum { value -= step }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(value - step >= minimum ? .blue : .quaternary)
                }
                .buttonStyle(.plain)

                Text("\(value)")
                    .font(.title3.monospacedDigit().weight(.semibold))
                    .frame(minWidth: 30, alignment: .center)

                Button {
                    value += step
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct WeightControl: View {
    let label: String
    @Binding var weight: Double
    let step: Double

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.tertiary)
                .kerning(0.5)

            HStack(spacing: 14) {
                Button {
                    if weight - step >= 0 { weight -= step }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(weight - step >= 0 ? .blue : .quaternary)
                }
                .buttonStyle(.plain)

                Text(formatted)
                    .font(.title3.monospacedDigit().weight(.semibold))
                    .frame(minWidth: 52, alignment: .center)

                Button {
                    weight += step
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var formatted: String {
        weight.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(weight))
            : String(format: "%.1f", weight)
    }
}
