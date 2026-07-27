import Foundation
import Testing
@testable import HealthTrackerData

struct DateKeyTests {
    // Fixed, non-DST-observing zone for boundary tests that shouldn't care
    // about DST at all -- keeps these deterministic regardless of the host
    // machine's local time zone.
    private let utc: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }()

    // A real DST-observing zone, used only by the DST-specific tests below.
    private let newYork: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "America/New_York")!
        return cal
    }()

    @Test func previousDayAcrossMonthBoundary() {
        // 2026 is not a leap year, so February has 28 days.
        #expect(DateKey.previousDay("2026-03-01", calendar: utc) == "2026-02-28")
    }

    @Test func previousDayAcrossYearBoundary() {
        #expect(DateKey.previousDay("2026-01-01", calendar: utc) == "2025-12-31")
    }

    // US DST began 2026-03-08 (clocks spring forward 2am -> 3am, a 23-hour
    // day). A fixed 24-hour subtraction would land on the wrong calendar
    // day; calendar-based day arithmetic must not.
    @Test func previousDayAcrossSpringForward() {
        #expect(DateKey.previousDay("2026-03-09", calendar: newYork) == "2026-03-08")
        #expect(DateKey.previousDay("2026-03-08", calendar: newYork) == "2026-03-07")
    }

    // US DST ended 2026-11-01 (clocks fall back 2am -> 1am, a 25-hour day).
    @Test func previousDayAcrossFallBack() {
        #expect(DateKey.previousDay("2026-11-02", calendar: newYork) == "2026-11-01")
        #expect(DateKey.previousDay("2026-11-01", calendar: newYork) == "2026-10-31")
    }

    @Test func roundTripsThroughDateAndBack() {
        for key in ["2026-01-01", "2026-02-28", "2026-03-08", "2026-11-01", "2025-12-31"] {
            let date = DateKey.date(from: key, calendar: newYork)
            #expect(date != nil)
            #expect(DateKey.key(from: date!, calendar: newYork) == key)
        }
    }

    @Test func dateFromInvalidKeyIsNil() {
        #expect(DateKey.date(from: "not-a-date", calendar: utc) == nil)
    }
}
