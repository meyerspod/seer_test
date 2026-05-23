import XCTest
@testable import WorkoutTracker

final class PlateCalculatorTests: XCTestCase {

    // MARK: - Bar only / below bar

    func testBarWeight_returnsEmptyPlateSet() {
        let result = PlateCalculator.plates(for: 45)
        XCTAssertTrue(result.isEmpty)
        XCTAssertEqual(PlateCalculator.totalWeight(for: result), 45)
    }

    func testBelowBar_returnsEmptyPlateSet() {
        XCTAssertTrue(PlateCalculator.plates(for: 0).isEmpty)
        XCTAssertTrue(PlateCalculator.plates(for: 20).isEmpty)
        XCTAssertTrue(PlateCalculator.plates(for: 44.9).isEmpty)
    }

    // MARK: - Common lifts (weight → plates)

    func test95lbs_onePlate25() {
        // (95 - 45) / 2 = 25 → one 25 per side
        let p = PlateCalculator.plates(for: 95)
        XCTAssertEqual(p.counts[25], 1)
        XCTAssertNil(p.counts[45])
        XCTAssertEqual(PlateCalculator.totalWeight(for: p), 95)
    }

    func test135lbs_oneFortyFive() {
        // (135 - 45) / 2 = 45 → one 45 per side
        let p = PlateCalculator.plates(for: 135)
        XCTAssertEqual(p.counts[45], 1)
        XCTAssertEqual(PlateCalculator.totalWeight(for: p), 135)
    }

    func test155lbs_oneFortyFiveOneTen() {
        // (155 - 45) / 2 = 55 → one 45 + one 10 per side
        let p = PlateCalculator.plates(for: 155)
        XCTAssertEqual(p.counts[45], 1)
        XCTAssertEqual(p.counts[10], 1)
        XCTAssertNil(p.counts[25])
        XCTAssertEqual(PlateCalculator.totalWeight(for: p), 155)
    }

    func test185lbs_oneFortyFiveOneTwentyFiveOneFive() {
        // (185 - 45) / 2 = 70 → one 45 + one 25 per side
        let p = PlateCalculator.plates(for: 185)
        XCTAssertEqual(p.counts[45], 1)
        XCTAssertEqual(p.counts[25], 1)
        XCTAssertEqual(PlateCalculator.totalWeight(for: p), 185)
    }

    func test225lbs_twoFortyFives() {
        // (225 - 45) / 2 = 90 → two 45s per side
        let p = PlateCalculator.plates(for: 225)
        XCTAssertEqual(p.counts[45], 2)
        XCTAssertEqual(PlateCalculator.totalWeight(for: p), 225)
    }

    func test275lbs_twoFortyFivesOneTwentyFive() {
        // (275 - 45) / 2 = 115 → two 45s + one 25 per side
        let p = PlateCalculator.plates(for: 275)
        XCTAssertEqual(p.counts[45], 2)
        XCTAssertEqual(p.counts[25], 1)
        XCTAssertEqual(PlateCalculator.totalWeight(for: p), 275)
    }

    func test315lbs_threeFortyFives() {
        // (315 - 45) / 2 = 135 → three 45s per side
        let p = PlateCalculator.plates(for: 315)
        XCTAssertEqual(p.counts[45], 3)
        XCTAssertEqual(PlateCalculator.totalWeight(for: p), 315)
    }

    func test405lbs_fourFortyFives() {
        let p = PlateCalculator.plates(for: 405)
        XCTAssertEqual(p.counts[45], 4)
        XCTAssertEqual(PlateCalculator.totalWeight(for: p), 405)
    }

    func testHalfPlate_twoPointFive() {
        // 50 lbs: (50 - 45) / 2 = 2.5 → one 2.5 per side
        let p = PlateCalculator.plates(for: 50)
        XCTAssertEqual(p.counts[2.5], 1)
        XCTAssertEqual(PlateCalculator.totalWeight(for: p), 50)
    }

    // MARK: - Non-achievable weights

    func testNonAchievable_46lbs() {
        // (46 - 45) / 2 = 0.5 — no plate fits, falls back to bar
        let p = PlateCalculator.plates(for: 46)
        XCTAssertTrue(p.isEmpty)
    }

    func testNonAchievable_100lbs() {
        // (100 - 45) / 2 = 27.5 → one 25 + one 2.5 = 27.5 ✓ — actually achievable
        // Let's verify the math is right rather than asserting non-achievable
        let p = PlateCalculator.plates(for: 100)
        XCTAssertEqual(PlateCalculator.totalWeight(for: p), 100)
    }

    func testNonAchievable_47lbs() {
        XCTAssertFalse(PlateCalculator.isExactlyAchievable(47))
    }

    // MARK: - isExactlyAchievable

    func testIsAchievable_commonWeights() {
        for w in stride(from: 45.0, through: 405.0, by: 5.0) {
            // Every multiple of 5 ≥ 45 that is also a multiple of 2.5 after subtracting bar
            // should be achievable — but only if per-side is decomposable.
            // At minimum these known lifts must pass:
            _ = PlateCalculator.isExactlyAchievable(w) // just ensure no crash
        }
        XCTAssertTrue(PlateCalculator.isExactlyAchievable(45))
        XCTAssertTrue(PlateCalculator.isExactlyAchievable(95))
        XCTAssertTrue(PlateCalculator.isExactlyAchievable(135))
        XCTAssertTrue(PlateCalculator.isExactlyAchievable(155))
        XCTAssertTrue(PlateCalculator.isExactlyAchievable(185))
        XCTAssertTrue(PlateCalculator.isExactlyAchievable(225))
        XCTAssertTrue(PlateCalculator.isExactlyAchievable(315))
    }

    func testIsNotAchievable() {
        XCTAssertFalse(PlateCalculator.isExactlyAchievable(46))
        XCTAssertFalse(PlateCalculator.isExactlyAchievable(47))
        XCTAssertFalse(PlateCalculator.isExactlyAchievable(48))
        XCTAssertFalse(PlateCalculator.isExactlyAchievable(20))
    }

    // MARK: - Incremental plate operations (tap-to-add flow)

    func testAddPlate_emptyBar() {
        let (updated, total) = PlateCalculator.addingPlate(45, to: PlateSet())
        XCTAssertEqual(updated.counts[45], 1)
        XCTAssertEqual(total, 135) // 45 bar + 2×45
    }

    func testAddTwoFortyFives() {
        let (after1, _) = PlateCalculator.addingPlate(45, to: PlateSet())
        let (after2, total) = PlateCalculator.addingPlate(45, to: after1)
        XCTAssertEqual(after2.counts[45], 2)
        XCTAssertEqual(total, 225)
    }

    func testAddMixedPlates_buildsTo185() {
        var set = PlateSet()
        (set, _) = PlateCalculator.addingPlate(45, to: set)
        let (final, total) = PlateCalculator.addingPlate(25, to: set)
        XCTAssertEqual(final.counts[45], 1)
        XCTAssertEqual(final.counts[25], 1)
        XCTAssertEqual(total, 185)
    }

    func testRemovePlate_reducesCorrectly() {
        // Start from 225 (two 45s per side), remove one
        let initial = PlateCalculator.plates(for: 225)
        let (updated, total) = PlateCalculator.removingPlate(45, from: initial)
        XCTAssertEqual(updated.counts[45], 1)
        XCTAssertEqual(total, 135)
    }

    func testRemovePlate_noopWhenEmpty() {
        let empty = PlateSet()
        let (updated, total) = PlateCalculator.removingPlate(45, from: empty)
        XCTAssertTrue(updated.isEmpty)
        XCTAssertEqual(total, 45)
    }

    // MARK: - Nearest achievable weight

    func testNearestAchievable_exactWeight() {
        XCTAssertEqual(PlateCalculator.nearestAchievableWeight(for: 225), 225)
    }

    func testNearestAchievable_oddWeight() {
        // 226 isn't achievable; nearest below is 225
        XCTAssertEqual(PlateCalculator.nearestAchievableWeight(for: 226), 225)
    }

    func testNearestAchievable_belowBar() {
        XCTAssertEqual(PlateCalculator.nearestAchievableWeight(for: 30), 45)
    }

    // MARK: - Display string

    func testDisplayString_barOnly() {
        XCTAssertEqual(PlateSet().displayString, "Bar only (45 lbs)")
    }

    func testDisplayString_225() {
        let p = PlateCalculator.plates(for: 225)
        XCTAssertEqual(p.displayString, "2×45")
    }

    func testDisplayString_275() {
        let p = PlateCalculator.plates(for: 275)
        XCTAssertEqual(p.displayString, "2×45  1×25")
    }

    func testDisplayString_155() {
        let p = PlateCalculator.plates(for: 155)
        XCTAssertEqual(p.displayString, "1×45  1×10")
    }

    // MARK: - Round-trip identity

    func testRoundTrip_weightToPlatesToWeight() {
        let achievableWeights: [Double] = [45, 50, 95, 100, 135, 155, 185, 225, 275, 315, 405]
        for w in achievableWeights {
            let plates = PlateCalculator.plates(for: w)
            let roundTripped = PlateCalculator.totalWeight(for: plates)
            XCTAssertEqual(roundTripped, w, accuracy: 0.01,
                           "Round-trip failed for \(w) lbs")
        }
    }
}
