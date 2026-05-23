import Foundation

// MARK: - PlateSet

/// Immutable snapshot of plates loaded per side of the barbell.
struct PlateSet: Equatable {

    /// All denominations supported, heaviest-first. Order drives display.
    static let denominations: [Double] = [45, 25, 10, 5, 2.5]

    /// Plate-weight → count per side. Absent key means zero plates of that denomination.
    var counts: [Double: Int]

    init(counts: [Double: Int] = [:]) {
        self.counts = counts
    }

    // MARK: Derived properties

    var isEmpty: Bool {
        counts.values.allSatisfy { $0 == 0 }
    }

    /// Plates in heaviest-first order, omitting denominations with a zero count.
    var orderedPlates: [(weight: Double, count: Int)] {
        PlateSet.denominations.compactMap { w in
            guard let c = counts[w], c > 0 else { return nil }
            return (weight: w, count: c)
        }
    }

    /// Total weight loaded on one side (not including the bar).
    var totalPerSide: Double {
        PlateSet.denominations.reduce(0) { $0 + Double(counts[$1] ?? 0) * $1 }
    }

    // MARK: Display

    /// Human-readable summary, e.g. "2×45  1×25" or "Bar only (45 lbs)".
    var displayString: String {
        guard !isEmpty else { return "Bar only (45 lbs)" }
        return orderedPlates
            .map { "\($0.count)×\(formatted($0.weight))" }
            .joined(separator: "  ")
    }

    private func formatted(_ w: Double) -> String {
        w.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(w))
            : String(format: "%.1f", w)
    }
}

// MARK: - PlateCalculator

/// Pure math engine. No state, no SwiftUI, no SwiftData.
enum PlateCalculator {

    static let barWeight: Double = 45

    // MARK: Weight → Plates

    /// Greedy decomposition of `totalWeight` into plates per side.
    /// Returns an empty PlateSet if the weight is ≤ bar weight.
    static func plates(for totalWeight: Double) -> PlateSet {
        guard totalWeight > barWeight else { return PlateSet() }

        var remaining = (totalWeight - barWeight) / 2.0
        var counts: [Double: Int] = [:]

        for denomination in PlateSet.denominations {
            let n = Int(remaining / denomination)
            if n > 0 {
                counts[denomination] = n
                remaining -= Double(n) * denomination
            }
        }

        return PlateSet(counts: counts)
    }

    // MARK: Plates → Weight

    /// Total barbell weight for the given PlateSet.
    static func totalWeight(for plateSet: PlateSet) -> Double {
        barWeight + 2 * plateSet.totalPerSide
    }

    // MARK: Incremental plate operations

    /// Add one plate of `denomination` per side. Returns updated set + new total.
    static func addingPlate(
        _ denomination: Double,
        to plateSet: PlateSet
    ) -> (plates: PlateSet, total: Double) {
        var updated = plateSet
        updated.counts[denomination, default: 0] += 1
        return (updated, totalWeight(for: updated))
    }

    /// Remove one plate of `denomination` per side (noop if none loaded).
    /// Returns updated set + new total.
    static func removingPlate(
        _ denomination: Double,
        from plateSet: PlateSet
    ) -> (plates: PlateSet, total: Double) {
        var updated = plateSet
        let current = updated.counts[denomination] ?? 0
        if current > 0 {
            updated.counts[denomination] = current - 1
        }
        return (updated, totalWeight(for: updated))
    }

    // MARK: Validation

    /// True when `weight` can be loaded exactly with the available plate denominations.
    static func isExactlyAchievable(_ weight: Double) -> Bool {
        guard weight >= barWeight else { return false }
        let computed = totalWeight(for: plates(for: weight))
        return abs(computed - weight) < 0.01
    }

    /// Nearest achievable weight at or below `weight`.
    /// Useful for showing users the closest valid target when they type an odd number.
    static func nearestAchievableWeight(for weight: Double) -> Double {
        guard weight >= barWeight else { return barWeight }
        // Step down in 2.5-lb increments (smallest bilateral change) until achievable.
        var candidate = weight
        while candidate >= barWeight {
            if isExactlyAchievable(candidate) { return candidate }
            candidate -= 2.5
        }
        return barWeight
    }
}
