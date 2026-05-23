import SwiftUI

// MARK: - PlateCalculatorSheet

struct PlateCalculatorSheet: View {
    let targetWeight: Double
    @Binding var confirmedWeight: Double
    @Binding var isPresented: Bool

    @State private var inputText: String = ""
    @State private var plateSet: PlateSet = PlateSet()
    @State private var displayedTotal: Double = PlateCalculator.barWeight
    @FocusState private var inputFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    weightInputSection
                    plateBarSection
                    Divider().padding(.vertical, 2)
                    quickAddSection
                    Divider().padding(.vertical, 2)
                    clearButton
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Plate Calculator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirm") {
                        confirmedWeight = displayedTotal
                        isPresented = false
                    }
                    .fontWeight(.bold)
                    .foregroundStyle(.green)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { inputFocused = false }
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.height(460)])
        .presentationDragIndicator(.visible)
        .onAppear { initialize() }
    }

    // MARK: - Sections

    private var weightInputSection: some View {
        VStack(spacing: 4) {
            Text("TOTAL WEIGHT")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .kerning(1)

            HStack(alignment: .lastTextBaseline, spacing: 6) {
                TextField("0", text: $inputText)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .focused($inputFocused)
                    .frame(maxWidth: 200)
                    .onChange(of: inputText) { _, newValue in handleTyped(newValue) }

                Text("lbs")
                    .font(.title2.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 6)
            }

            Text("Target: \(formatted(targetWeight)) lbs")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.top, 16)
        .padding(.bottom, 10)
    }

    private var plateBarSection: some View {
        VStack(spacing: 6) {
            ScrollView(.horizontal, showsIndicators: false) {
                PlateBarView(plateSet: plateSet)
                    .padding(.horizontal, 24)
            }

            Text(plateSet.displayString)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .frame(minHeight: 18)
                .animation(.easeInOut, value: plateSet.displayString)
        }
        .padding(.vertical, 10)
    }

    private var quickAddSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ADD PER SIDE")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.tertiary)
                .kerning(0.8)
                .padding(.horizontal, 20)

            HStack(spacing: 8) {
                ForEach(PlateSet.denominations, id: \.self) { denomination in
                    PlateAddButton(denomination: denomination) {
                        addPlate(denomination)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 14)
    }

    private var clearButton: some View {
        Button(action: clearPlates) {
            Label("Clear All Plates", systemImage: "arrow.counterclockwise")
                .font(.subheadline)
                .foregroundStyle(.red)
        }
        .padding(.vertical, 14)
    }

    // MARK: - Logic

    private func initialize() {
        displayedTotal = confirmedWeight
        plateSet       = PlateCalculator.plates(for: confirmedWeight)
        inputText      = formatted(confirmedWeight)
    }

    private func handleTyped(_ text: String) {
        guard let value = Double(text), value >= 0 else { return }
        displayedTotal = value
        plateSet       = PlateCalculator.plates(for: value)
    }

    private func addPlate(_ denomination: Double) {
        inputFocused = false
        let (updated, total) = PlateCalculator.addingPlate(denomination, to: plateSet)
        plateSet       = updated
        displayedTotal = total
        inputText      = formatted(total)
    }

    private func clearPlates() {
        inputFocused   = false
        plateSet       = PlateSet()
        displayedTotal = PlateCalculator.barWeight
        inputText      = formatted(PlateCalculator.barWeight)
    }

    private func formatted(_ w: Double) -> String {
        w.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(w)) : String(format: "%.1f", w)
    }
}

// MARK: - PlateBarView

struct PlateBarView: View {
    let plateSet: PlateSet

    private let plateColors: [Double: Color] = [
        45:  Color(red: 0.85, green: 0.15, blue: 0.15),
        25:  Color(red: 0.20, green: 0.40, blue: 0.90),
        10:  Color(red: 0.15, green: 0.65, blue: 0.30),
        5:   Color(red: 0.90, green: 0.72, blue: 0.08),
        2.5: Color(white: 0.55)
    ]
    private let plateHeights: [Double: CGFloat] = [
        45: 64, 25: 52, 10: 44, 5: 36, 2.5: 28
    ]
    private let plateWidths: [Double: CGFloat] = [
        45: 14, 25: 12, 10: 10, 5: 10, 2.5: 8
    ]

    // Expand plate counts into an ordered flat list (heaviest first)
    private var expandedPlates: [Double] {
        PlateSet.denominations.flatMap { d in
            Array(repeating: d, count: plateSet.counts[d] ?? 0)
        }
    }

    var body: some View {
        HStack(spacing: 2) {
            // Left side — innermost plate is heaviest (index 0), extends outward
            ForEach(Array(expandedPlates.enumerated()), id: \.offset) { _, w in
                plateShape(for: w)
            }

            // Bar: collar → shaft → collar
            HStack(spacing: 0) {
                Capsule().fill(Color(white: 0.50)).frame(width: 6, height: 14)
                Capsule().fill(Color(white: 0.28)).frame(width: expandedPlates.isEmpty ? 120 : 44, height: 8)
                Capsule().fill(Color(white: 0.50)).frame(width: 6, height: 14)
            }

            // Right side — mirror of left
            ForEach(Array(expandedPlates.reversed().enumerated()), id: \.offset) { _, w in
                plateShape(for: w)
            }
        }
        .frame(height: 72)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: plateSet)
    }

    @ViewBuilder
    private func plateShape(for weight: Double) -> some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(plateColors[weight] ?? .gray)
            .frame(width: plateWidths[weight] ?? 10, height: plateHeights[weight] ?? 40)
    }
}

// MARK: - PlateAddButton

struct PlateAddButton: View {
    let denomination: Double
    let action: () -> Void

    private let colors: [Double: Color] = [
        45:  Color(red: 0.85, green: 0.15, blue: 0.15),
        25:  Color(red: 0.20, green: 0.40, blue: 0.90),
        10:  Color(red: 0.15, green: 0.65, blue: 0.30),
        5:   Color(red: 0.90, green: 0.72, blue: 0.08),
        2.5: Color(white: 0.55)
    ]

    private var label: String {
        denomination.truncatingRemainder(dividingBy: 1) == 0
            ? "+\(Int(denomination))"
            : "+\(String(format: "%.1f", denomination))"
    }

    private var accent: Color { colors[denomination] ?? .gray }

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(.bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(accent.opacity(0.18))
                .foregroundStyle(accent)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(accent.opacity(0.45), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
