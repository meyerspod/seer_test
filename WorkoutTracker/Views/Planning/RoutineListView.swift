import SwiftUI
import SwiftData

struct RoutineListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutRoutine.createdAt, order: .reverse) private var routines: [WorkoutRoutine]

    @State private var showingNewRoutine = false

    var body: some View {
        NavigationStack {
            Group {
                if routines.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(routines) { routine in
                            NavigationLink(destination: RoutineDetailView(routine: routine)) {
                                RoutineRow(routine: routine)
                            }
                        }
                        .onDelete(perform: deleteRoutines)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Routines")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingNewRoutine = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title3.weight(.semibold))
                    }
                }
            }
            .sheet(isPresented: $showingNewRoutine) {
                NewRoutineSheet(isPresented: $showingNewRoutine)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 56))
                .foregroundStyle(.tertiary)
            Text("No Routines Yet")
                .font(.title3.weight(.semibold))
            Text("Tap + to build your first workout.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("Create Routine") {
                showingNewRoutine = true
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func deleteRoutines(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(routines[index])
        }
    }
}

private struct RoutineRow: View {
    let routine: WorkoutRoutine

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(routine.name)
                .font(.headline)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var subtitle: String {
        let exCount = routine.exercises.count
        if exCount == 0 { return "No exercises" }
        let setCount = routine.exercises.reduce(0) { $0 + $1.sets.count }
        return "\(exCount) exercise\(exCount == 1 ? "" : "s") · \(setCount) set\(setCount == 1 ? "" : "s")"
    }
}

struct NewRoutineSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var isPresented: Bool

    @State private var name = ""
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section("Routine Name") {
                    TextField("e.g. Push Day", text: $name)
                        .font(.body)
                        .focused($focused)
                }
            }
            .navigationTitle("New Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createRoutine()
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

    private func createRoutine() {
        guard !trimmedName.isEmpty else { return }
        let routine = WorkoutRoutine(name: trimmedName)
        modelContext.insert(routine)
        isPresented = false
    }
}
