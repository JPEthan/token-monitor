import Foundation

/// The inclusive start and exclusive end of a UTC calendar month.
public struct UTCMonthRange: Equatable, Sendable {
    public let start: Date
    public let endExclusive: Date

    public init(start: Date, endExclusive: Date) {
        precondition(start <= endExclusive, "Month range start must not be after its end")
        self.start = start
        self.endExclusive = endExclusive
    }

    public var startUnixSeconds: Int64 {
        Int64(start.timeIntervalSince1970)
    }

    public var endUnixSeconds: Int64 {
        Int64(endExclusive.timeIntervalSince1970)
    }

    /// Returns the UTC calendar month containing `date`.
    public static func containing(_ date: Date = Date()) -> UTCMonthRange {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        guard let interval = calendar.dateInterval(of: .month, for: date) else {
            preconditionFailure("Gregorian UTC calendar could not create a month interval")
        }

        return UTCMonthRange(start: interval.start, endExclusive: interval.end)
    }

    /// Returns the current UTC calendar month. `now` is injectable for tests.
    public static func current(now: Date = Date()) -> UTCMonthRange {
        containing(now)
    }
}
