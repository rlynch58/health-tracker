import Foundation
import SwiftData

/// One day's water/weight record. `waterOz` MUST stay optional: `nil` means
/// "never logged today," `0` means "deliberately logged zero ounces" -- see
/// ARCHITECTURE_NOTES.md §8. Do not give it a non-nil default or collapse
/// the two states.
///
/// CLOUDKIT: every stored property is optional or has a default value, and
/// there are no unique constraints -- see `DailyLogStore`, which is the only
/// sanctioned read path and is what actually copes with CloudKit's inability
/// to enforce one row per `dateKey`.
///
/// CLAMPING: same private-backing / computed-property pattern as `Meal` --
/// see that file's header comment for why `didSet` was avoided.
///
/// `waterOz`'s ceiling: the web app never bounds the day's *cumulative*
/// water total directly -- only a single custom-add amount is clamped, via
/// `MAX_WATER_ENTRY`. A day's running total is closer in scale to the daily
/// water *goal* than to one add, so this ports it against `maxWaterGoal`
/// (300) rather than `maxWaterEntry` (200) -- a judgment call, not a value
/// read directly off a `MAX_*` constant for this exact field, since no such
/// constant exists in the web app.
@Model
final class DailyLog {
    var id: UUID = UUID()
    var dateKey: String = ""
    var updatedAt: Date = Date()

    private var _waterOz: Int?
    private var _weightLbs: Double?

    var waterOz: Int? {
        get { _waterOz }
        set { _waterOz = newValue.map { Limits.clamp($0, max: Limits.maxWaterGoal) } }
    }
    var weightLbs: Double? {
        get { _weightLbs }
        set { _weightLbs = newValue.map { Limits.clamp($0, max: Double(Limits.maxWeightLbs)) } }
    }

    init(
        dateKey: String,
        waterOz: Int? = nil,
        weightLbs: Double? = nil,
        updatedAt: Date = Date()
    ) {
        self.id = UUID()
        self.dateKey = dateKey
        self.updatedAt = updatedAt
        // Routed through the clamped setters above.
        self.waterOz = waterOz
        self.weightLbs = weightLbs
    }
}
