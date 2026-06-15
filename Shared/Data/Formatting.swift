import Foundation

/// Number & date formatting ported from the design's `data.jsx` (en-US, USD).
enum Format {

    private static let grouping: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = Locale(identifier: "en_US")
        return f
    }()

    /// `$1,234.56` (dp=2 default) — matches `money()`.
    static func money(_ n: Double, dp: Int = 2) -> String {
        grouping.minimumFractionDigits = dp
        grouping.maximumFractionDigits = dp
        let s = grouping.string(from: NSNumber(value: n)) ?? "0"
        return "$" + s
    }

    /// Compact money: `$1.23M` / `$12.3K` / `$1,234` — matches `moneyK()`.
    static func moneyK(_ n: Double) -> String {
        if n >= 1_000_000 { return "$" + String(format: "%.2f", n / 1_000_000) + "M" }
        if n >= 10_000 { return "$" + String(format: "%.1f", n / 1_000) + "K" }
        grouping.minimumFractionDigits = 0
        grouping.maximumFractionDigits = 0
        return "$" + (grouping.string(from: NSNumber(value: n.rounded())) ?? "0")
    }

    /// Signed percent: `+12.3%` — matches `pct()`.
    static func pct(_ n: Double) -> String {
        (n >= 0 ? "+" : "") + String(format: "%.1f", n) + "%"
    }

    /// Compact integer: `1.23M` / `12.3k` / `1,234` — matches `compact()`.
    static func compact(_ value: Double) -> String {
        let n = value.rounded()
        if n >= 1_000_000 {
            return trimTrailingZeros(String(format: "%.2f", n / 1_000_000)) + "M"
        }
        if n >= 1_000 {
            var s = String(format: "%.1f", n / 1_000)
            if s.hasSuffix(".0") { s.removeLast(2) }
            return s + "k"
        }
        grouping.minimumFractionDigits = 0
        grouping.maximumFractionDigits = 0
        return grouping.string(from: NSNumber(value: n)) ?? "0"
    }

    private static func trimTrailingZeros(_ s: String) -> String {
        guard s.contains(".") else { return s }
        var out = s
        while out.hasSuffix("0") { out.removeLast() }
        if out.hasSuffix(".") { out.removeLast() }
        return out
    }

    // MARK: Dates

    private static let months = ["January","February","March","April","May","June","July","August","September","October","November","December"]
    private static let monthsShort = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
    /// Day-of-week labels, Sunday-first (matches JS getDay()).
    static let dow = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]

    /// `15 June 2026` — matches `fmtDate()`.
    static func date(_ d: Date) -> String {
        let c = Calendar.utc.dateComponents([.year, .month, .day], from: d)
        return "\(c.day!) \(months[c.month! - 1]) \(c.year!)"
    }

    /// `Jun 15` — matches `fmtDateShort()`.
    static func dateShort(_ d: Date) -> String {
        let c = Calendar.utc.dateComponents([.month, .day], from: d)
        return "\(monthsShort[c.month! - 1]) \(c.day!)"
    }

    static func monthName(_ index0: Int) -> String { months[index0] }

    /// JS-style weekday index (Sun = 0).
    static func jsWeekday(_ d: Date) -> Int {
        Calendar.utc.component(.weekday, from: d) - 1
    }
}
