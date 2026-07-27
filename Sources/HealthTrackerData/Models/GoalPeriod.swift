import Foundation
import SwiftData

/// One row per goal change, dated by `effectiveDate`. `GoalResolver` finds
/// the row with the greatest `effectiveDate <= ` a requested date key -- see
/// ARCHITECTURE_NOTES.md §5.
///
/// This model deliberately collapses the web app's two-table split
/// (`user_settings` JSONB for current goals + sodium/sugar, `goal_periods`
/// for the three dated metrics) into one dated table that also carries
/// sodium/sugar. There is no separate "global goals" object and no
/// merge-with-global-goals step in `GoalResolver` -- every goal a day needs
/// comes from whichever `GoalPeriod` row is in effect for that day.
///
/// CLOUDKIT: every stored property is optional or has a default value, and
/// there are no unique constraints.
///
/// CLAMPING: same private-backing / computed-property pattern as `Meal` --
/// see that file's header comment for why `didSet` was avoided. All five
/// fields clamp against their `*Goal` ceiling (sodium has no separate goal
/// ceiling in the web app, so it reuses `maxSodium`, same as `Meal`).
@Model
final class GoalPeriod {
    var id: UUID = UUID()
    var effectiveDate: String = ""

    private var _calories: Int?
    private var _protein: Int?
    private var _water: Int?
    private var _sodium: Int?
    private var _sugar: Int?

    var calories: Int? {
        get { _calories }
        set { _calories = newValue.map { Limits.clamp($0, max: Limits.maxCaloriesGoal) } }
    }
    var protein: Int? {
        get { _protein }
        set { _protein = newValue.map { Limits.clamp($0, max: Limits.maxProteinGoal) } }
    }
    var water: Int? {
        get { _water }
        set { _water = newValue.map { Limits.clamp($0, max: Limits.maxWaterGoal) } }
    }
    var sodium: Int? {
        get { _sodium }
        set { _sodium = newValue.map { Limits.clamp($0, max: Limits.maxSodium) } }
    }
    var sugar: Int? {
        get { _sugar }
        set { _sugar = newValue.map { Limits.clamp($0, max: Limits.maxSugarGoal) } }
    }

    init(
        effectiveDate: String,
        calories: Int? = nil,
        protein: Int? = nil,
        water: Int? = nil,
        sodium: Int? = nil,
        sugar: Int? = nil
    ) {
        self.id = UUID()
        self.effectiveDate = effectiveDate
        // Routed through the clamped setters above.
        self.calories = calories
        self.protein = protein
        self.water = water
        self.sodium = sodium
        self.sugar = sugar
    }
}
