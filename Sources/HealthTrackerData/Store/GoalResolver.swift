import Foundation
import SwiftData

/// Resolves which `GoalPeriod` is in effect for a given day -- see
/// ARCHITECTURE_NOTES.md §5. The lookup itself (`resolve(for:in:)`) is a
/// pure, static function over a plain array so it's testable without a
/// `ModelContext`; `goals(for:)` is the ModelContext-backed convenience for
/// real use.
@MainActor
final class GoalResolver {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    /// Fetches all `GoalPeriod` rows and resolves the one in effect for `dateKey`.
    func goals(for dateKey: String) -> GoalPeriod? {
        let descriptor = FetchDescriptor<GoalPeriod>(
            sortBy: [SortDescriptor(\.effectiveDate, order: .forward)]
        )
        guard let periods = try? context.fetch(descriptor) else { return nil }
        return Self.resolve(for: dateKey, in: periods)
    }

    /// The `GoalPeriod` with the greatest `effectiveDate <= dateKey`. Falls
    /// back to the earliest period if none qualify (a date earlier than the
    /// oldest goal record). Returns `nil` only when `periods` is empty --
    /// there is no further fallback, since this model carries every field a
    /// caller could need (see the type's header comment: no
    /// merge-with-global-goals step is ported from the web app).
    nonisolated static func resolve(for dateKey: String, in periods: [GoalPeriod]) -> GoalPeriod? {
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
