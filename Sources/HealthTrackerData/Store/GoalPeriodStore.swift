import Foundation
import SwiftData

/// The reconciliation layer for `GoalPeriod`, mirroring what
/// `DailyLogStore` does for `DailyLog` -- CloudKit cannot enforce a unique
/// constraint on `effectiveDate` (see the HARD CLOUDKIT RULES: no
/// `@Attribute(.unique)` anywhere), so two devices syncing independently can
/// each create a `GoalPeriod` for the same `effectiveDate`.
///
/// Unlike `DailyLogStore`, which dedupes one `dateKey` at a time,
/// `GoalResolver` needs every period across every `effectiveDate` at once to
/// find the one in effect for a given day. So `cleanedPeriods()` fetches
/// everything, groups by `effectiveDate`, merges any group with more than
/// one row, deletes the extras, and returns the full cleaned array.
@MainActor
public final class GoalPeriodStore {
    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    /// Returns every `GoalPeriod`, with any CloudKit-duplicated
    /// `effectiveDate` groups merged down to one row first.
    public func cleanedPeriods() -> [GoalPeriod] {
        let descriptor = FetchDescriptor<GoalPeriod>()
        let all = (try? context.fetch(descriptor)) ?? []

        let grouped = Dictionary(grouping: all, by: { $0.effectiveDate })

        var result: [GoalPeriod] = []
        for (_, group) in grouped {
            if group.count == 1 {
                result.append(group[0])
            } else {
                result.append(merge(group))
            }
        }

        try? context.save()
        return result
    }

    /// Collapses duplicate same-`effectiveDate` rows into one, using the
    /// same field-by-field most-recent-non-nil semantics as
    /// `DailyLogStore.merge` -- see that file's doc comment for why. The
    /// secondary sort on `id.uuidString` makes the choice of canonical row
    /// deterministic across devices even when two rows share an identical
    /// `updatedAt`, which is what keeps every device's deletes agreeing
    /// with each other instead of colliding.
    private func merge(_ periods: [GoalPeriod]) -> GoalPeriod {
        let sorted = periods.sorted {
            if $0.updatedAt != $1.updatedAt {
                return $0.updatedAt > $1.updatedAt
            }
            return $0.id.uuidString > $1.id.uuidString
        }
        let canonical = sorted[0]

        canonical.calories = sorted.first(where: { $0.calories != nil })?.calories
        canonical.protein = sorted.first(where: { $0.protein != nil })?.protein
        canonical.water = sorted.first(where: { $0.water != nil })?.water
        canonical.sodium = sorted.first(where: { $0.sodium != nil })?.sodium
        canonical.sugar = sorted.first(where: { $0.sugar != nil })?.sugar

        for extra in sorted.dropFirst() {
            context.delete(extra)
        }
        return canonical
    }
}
