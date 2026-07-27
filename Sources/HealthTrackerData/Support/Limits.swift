import Foundation

/// Numeric ceilings, ported verbatim from the web app's `MAX_*` constants
/// (see index.html) and `CALORIE_STREAK_TOLERANCE`. These are generous
/// ceilings meant only to catch an accidental extra digit -- not tight
/// clinical limits. See ARCHITECTURE_NOTES.md §9.
///
/// Goal ceilings and entry ceilings are separate constants for the same
/// metric (a daily goal and a single meal's value are different orders of
/// magnitude) except sodium, which shares one ceiling across both contexts
/// since a single very salty meal and a full day's sodium budget are
/// already the same order of magnitude.
enum Limits {
    static let maxCaloriesGoal = 10_000
    static let maxCaloriesEntry = 5_000
    static let maxProteinGoal = 400
    static let maxProteinEntry = 300
    static let maxCarbsEntry = 500
    static let maxFatEntry = 300
    static let maxSodium = 10_000
    static let maxSugarGoal = 500
    static let maxSugarEntry = 300
    static let maxWaterGoal = 300
    static let maxWaterEntry = 200
    static let maxWeightLbs = 1_000

    /// §5: calories count toward a streak only within ±10% of that day's goal.
    static let calorieStreakTolerance = 0.10

    /// Clamps `value` into `minValue...maxValue`, floored at 0 by default --
    /// mirrors the web app's `clampNum(n, max) = Math.max(0, Math.min(max, n))`.
    static func clamp<T: Comparable & Numeric>(_ value: T, max maxValue: T, min minValue: T = .zero) -> T {
        Swift.max(minValue, Swift.min(maxValue, value))
    }
}
