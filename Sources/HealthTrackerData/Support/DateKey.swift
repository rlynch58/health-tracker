import Foundation

/// Local-calendar `YYYY-MM-DD` date keys. Per ARCHITECTURE_NOTES.md §1: a
/// day is decided once, at write time, from the device's local wall clock,
/// and is never re-derived from a stored timestamp using UTC math at read
/// time. Production callers use the no-argument overloads, which default to
/// `DateKey.calendar` -- a single `Calendar` pinned to `TimeZone.current` --
/// so "today" and "yesterday" are computed the exact same way everywhere in
/// the app. Every function also accepts an explicit `calendar:` so tests can
/// exercise DST/month/year-boundary arithmetic against a specific time zone
/// without depending on the host machine's local zone.
///
/// Day-to-day arithmetic goes through `Calendar.date(byAdding: .day, ...)`,
/// which is calendar-based (DST-aware), not a fixed 24-hour offset -- so a
/// day that spans a DST transition still advances by exactly one calendar
/// day.
enum DateKey {
    static let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone.current
        return cal
    }()

    private static func formatter(for calendar: Calendar) -> DateFormatter {
        let f = DateFormatter()
        f.calendar = calendar
        f.timeZone = calendar.timeZone
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }

    /// Today's local-calendar date key.
    static func today(calendar: Calendar = DateKey.calendar) -> String {
        key(from: Date(), calendar: calendar)
    }

    /// The local-calendar date key for `date`.
    static func key(from date: Date, calendar: Calendar = DateKey.calendar) -> String {
        formatter(for: calendar).string(from: date)
    }

    /// Parses a `YYYY-MM-DD` key back into the local-calendar midnight
    /// `Date` it represents, or `nil` if `key` isn't a valid date key.
    static func date(from key: String, calendar: Calendar = DateKey.calendar) -> Date? {
        formatter(for: calendar).date(from: key)
    }

    /// The date key for the local-calendar day immediately before `key`.
    /// Used by the streak walk-back. Falls back to returning `key` unchanged
    /// if `key` isn't parseable, since there's no sane "previous day" for an
    /// invalid key.
    static func previousDay(_ key: String, calendar: Calendar = DateKey.calendar) -> String {
        guard let date = date(from: key, calendar: calendar),
              let prev = calendar.date(byAdding: .day, value: -1, to: date) else {
            return key
        }
        return self.key(from: prev, calendar: calendar)
    }

    /// The date key for the local-calendar day immediately after `key`.
    static func nextDay(_ key: String, calendar: Calendar = DateKey.calendar) -> String {
        guard let date = date(from: key, calendar: calendar),
              let next = calendar.date(byAdding: .day, value: 1, to: date) else {
            return key
        }
        return self.key(from: next, calendar: calendar)
    }

    /// Whole local-calendar days from `from` to `to` (negative if `to`
    /// precedes `from`), or `nil` if either key is unparseable.
    static func daysBetween(_ from: String, _ to: String, calendar: Calendar = DateKey.calendar) -> Int? {
        guard let fromDate = date(from: from, calendar: calendar),
              let toDate = date(from: to, calendar: calendar) else { return nil }
        return calendar.dateComponents([.day], from: fromDate, to: toDate).day
    }
}
