import Foundation
import SwiftData

/// The only sanctioned read path for a day's `DailyLog`. CloudKit cannot
/// enforce a unique constraint on `dateKey` (see the HARD CLOUDKIT RULES --
/// no `@Attribute(.unique)` anywhere), so two devices syncing independently
/// can each create a `DailyLog` for the same day. `fetchOrCreate` is where
/// that gets reconciled: if more than one row turns up for `dateKey`, they
/// are merged into a single canonical row before anything downstream ever
/// sees them, and the extras are deleted.
@MainActor
public final class DailyLogStore {
    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    /// Returns the single `DailyLog` for `dateKey`, creating one if none
    /// exists, or merging duplicates into one if CloudKit sync produced more
    /// than one.
    public func fetchOrCreate(dateKey: String) -> DailyLog {
        let descriptor = FetchDescriptor<DailyLog>(
            predicate: #Predicate { $0.dateKey == dateKey },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        let matches = (try? context.fetch(descriptor)) ?? []

        let log: DailyLog
        if matches.isEmpty {
            log = DailyLog(dateKey: dateKey)
            context.insert(log)
        } else if matches.count == 1 {
            log = matches[0]
        } else {
            log = merge(matches)
        }
        try? context.save()
        return log
    }

    /// Collapses duplicate same-day rows into one. For each field
    /// independently, keeps the value from whichever row most recently set
    /// it to non-nil -- `nil` never overwrites a real value from an earlier
    /// row just because the row carrying `nil` happens to be more recent
    /// overall, since `nil` there means "this device never touched this
    /// field," not "clear it." This is what preserves the nil-vs-zero
    /// distinction on `waterOz` (§8) across a merge: a device that only
    /// logged weight contributes `nil` for water, not a competing `0`.
    ///
    /// `logs` need not be pre-sorted; this sorts by `updatedAt` itself.
    private func merge(_ logs: [DailyLog]) -> DailyLog {
        let sorted = logs.sorted { $0.updatedAt > $1.updatedAt }
        let canonical = sorted[0]

        canonical.waterOz = sorted.first(where: { $0.waterOz != nil })?.waterOz
        canonical.weightLbs = sorted.first(where: { $0.weightLbs != nil })?.weightLbs
        canonical.updatedAt = sorted[0].updatedAt

        for extra in sorted.dropFirst() {
            context.delete(extra)
        }
        return canonical
    }
}
