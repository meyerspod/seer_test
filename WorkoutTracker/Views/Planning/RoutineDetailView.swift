import SwiftUI
import SwiftData

struct RoutineDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var routine: WorkoutRoutine

    @State private var showingAddExercise = false

    private var sortedExercises: [ExerciseTarget] {
        routine.exercises.sorted { $0.order < $1.order }
    }

    var body: some View {
        List {
            if sortedExercises.isEmpty {
                Text("No exercises yet. Tap \"Add Exercise\" to begin.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .listRowBackground(Color.clear)
            }

            ForEach(sortedExercises) { exercise in
                NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {
                    ExerciseRow(exercise: exercise)
                }
            }
            .onDelete(perform: deleteExercises)

            Button {
                showingAddExercise = true
            } label: {
                Label("Add Exercise", systemImage: "plus.circle.fill")
                    .foregroundStyle(.blue)
                    .font(.body.weight(.medium))
            }
            .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
        .navigationTitle(routine.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                // "Start" wired in Step 4
                Button("Start") {}
                    .fontWeight(.bold)
                    .foregroundStyle(sortedExercises.isEmpty ? .gray : .green)
                    .disabled(sortedExercises.isEmpty)
            }
        }
        .sheet(isPresented: $showingAddExercise) {
            AddExerciseSheet(routine: routine, isPresented: $showingAddExercise)
        }
    }

    private func deleteExercises(at offsets: IndexSet) {
        let sorted = sortedExercises
        for index in offsets {
            modelContext.delete(sorted[index])
        }
    }
}

private struct ExerciseRow: View {
    let exercise: ExerciseTarget

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(exercise.name)
                .font(.headline)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var subtitle: String {
        let count = exercise.sets.count
        guard count > 0 else { return "No sets" }
        let sorted = exercise.sets.sorted { $0.index < $1.index }
        let reps = sorted.map { $0.targetReps }
        let weights = sorted.map { $0.targetWeight }
        if Set(reps).count == 1, Set(weights).count == 1,
           let r = reps.first, let w = weights.first {
            return "\(count) × \(r) reps @ \(formattedWeight(w)) lbs"
        }
        return "\(count) set\(count == 1 ? "" : "s")"
    }

    private func formattedWeight(_ w: Double) -> String {
        w.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(w)) : String(format: "%.1f", w)
    }
}

struct AddExerciseSheet: View {
    @Environment(\.modelContext) private var modelContext
    var routine: WorkoutRoutine
    @Binding var isPresented: Bool

    @State private var name = ""
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section("Exercise Name") {
                    TextField("e.g. Bench Press", text: $name)
                        .font(.body)
                        .focused($focused)
                }
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addExercise()
                    }
                    .fontWeight(.semibold)
                    .disabled(trimmedName.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
        .onAppear { focused = true }
    }

    private var trimmedName: String { name.trimmingCharacters(in: .whitespaces) }

    private func addExercise() {
        guard !trimmedName.isEmpty else { return }
        let exercise = ExerciseTarget(name: trimmedName, order: routine.exercises.count)
        routine.exercises.append(exercise)
        isPresented = false
    }
}
