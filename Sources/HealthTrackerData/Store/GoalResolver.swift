import Foundation
import SwiftData

/// Resolves which `GoalPeriod` is in effect for a given day -- see
/// ARCHITECTURE_NOTES.md §5. The lookup itself (`resolve(for:in:)`) is a
/// pure, static function over a plain array so it's testable without a
/// `ModelContext`; `goals(for:)` is the ModelContext-backed convenience for
/// real use.
///
/// `goals(for:)` reads through `GoalPeriodStore.cleanedPeriods()` rather
/// than fetching `GoalPeriod` rows directly, so any CloudKit-duplicated
/// `effectiveDate` groups are merged down to one row before `resolve`
/// ever sees them.
@MainActor
public final class GoalResolver {
    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    /// Fetches all `GoalPeriod` rows (deduplicated) and resolves the one in
    /// effect for `dateKey`.
    public func goals(for dateKey: String) -> GoalPeriod? {
        let periods = GoalPeriodStore(context: context).cleanedPeriods()
        return Self.resolve(for: dateKey, in: periods)
    }

    /// The `GoalPeriod` with the greatest `effectiveDate <= dateKey`. Falls
    /// back to the earliest period if none qualify (a date earlier than the
    /// oldest goal record). Returns `nil` only when `periods` is empty --
    /// there is no further fallback, since this model carries every field a
    /// caller could need (see the type's header comment: no
    /// merge-with-global-goals step is ported from the web app).
    public nonisolated static func resolve(for dateKey: String, in periods: [GoalPeriod]) -> GoalPeriod? {
        guard !periods.isEmpty else { return nil }
        var match: GoalPeriod?
        for period in periods where period.effectiveDate <= dateKey {
            if match == nil || period.effectiveDate > match!.effectiveDate {
                match = period
            }
        }
        return match ?? periods.min(by: { $0.effectiveDate < $1.effectiveDate })
    }
}
