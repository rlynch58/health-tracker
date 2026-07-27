import Foundation
import Testing
@testable import HealthTrackerData

struct GoalResolverTests {
    @Test func exactDateMatch() {
        let periods = [
            GoalPeriod(effectiveDate: "2026-01-01", calories: 1800),
            GoalPeriod(effectiveDate: "2026-03-01", calories: 2000),
        ]
        let result = GoalResolver.resolve(for: "2026-03-01", in: periods)
        #expect(result?.effectiveDate == "2026-03-01")
        #expect(result?.calories == 2000)
    }

    @Test func dateBetweenTwoPeriodsUsesTheEarlierOne() {
        let periods = [
            GoalPeriod(effectiveDate: "2026-01-01", calories: 1800),
            GoalPeriod(effectiveDate: "2026-03-01", calories: 2000),
        ]
        let result = GoalResolver.resolve(for: "2026-02-15", in: periods)
        #expect(result?.effectiveDate == "2026-01-01")
        #expect(result?.calories == 1800)
    }

    @Test func dateBeforeAllPeriodsFallsBackToEarliest() {
        let periods = [
            GoalPeriod(effectiveDate: "2026-01-01", calories: 1800),
            GoalPeriod(effectiveDate: "2026-03-01", calories: 2000),
        ]
        let result = GoalResolver.resolve(for: "2025-06-01", in: periods)
        #expect(result?.effectiveDate == "2026-01-01")
    }

    @Test func emptyPeriodListReturnsNil() {
        let result = GoalResolver.resolve(for: "2026-01-01", in: [])
        #expect(result == nil)
    }

    @Test func unsortedInputStillResolvesCorrectly() {
        // resolve(for:in:) must not assume its input is pre-sorted.
        let periods = [
            GoalPeriod(effectiveDate: "2026-03-01", calories: 2000),
            GoalPeriod(effectiveDate: "2026-01-01", calories: 1800),
            GoalPeriod(effectiveDate: "2026-02-01", calories: 1900),
        ]
        let result = GoalResolver.resolve(for: "2026-02-20", in: periods)
        #expect(result?.effectiveDate == "2026-02-01")
        #expect(result?.calories == 1900)
    }
}
