import Foundation
import XCTest
@testable import TokenQuotaCore

final class UTCMonthRangeTests: XCTestCase {
    func leapYearMonthUsesUTCAndExclusiveEnd() throws {
        let formatter = makeFormatter()
        let date = try XCTUnwrap(formatter.date(from: "2024-02-29T23:30:00Z"))
        let range = UTCMonthRange.containing(date)

        XCTAssertEqual(formatter.string(from: range.start), "2024-02-01T00:00:00Z")
        XCTAssertEqual(formatter.string(from: range.endExclusive), "2024-03-01T00:00:00Z")
        XCTAssertEqual(range.startUnixSeconds, 1_706_745_600)
        XCTAssertEqual(range.endUnixSeconds, 1_709_251_200)
    }

    func decemberRangeEndsAtNextYear() throws {
        let formatter = makeFormatter()
        let date = try XCTUnwrap(formatter.date(from: "2026-12-31T23:59:59Z"))
        let range = UTCMonthRange.current(now: date)

        XCTAssertEqual(formatter.string(from: range.start), "2026-12-01T00:00:00Z")
        XCTAssertEqual(formatter.string(from: range.endExclusive), "2027-01-01T00:00:00Z")
    }

    private func makeFormatter() -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }
}
