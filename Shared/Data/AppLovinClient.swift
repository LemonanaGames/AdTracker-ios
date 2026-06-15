import Foundation

/// AppLovin MAX reporting API client.
/// Docs: https://developers.applovin.com/en/max/reporting-api/  (GET https://r.applovin.com/maxReport)
///
/// NOTE: confirm the exact column/metric names against your account's API response;
/// parsing here is defensive and skips unknown fields.
struct AppLovinClient {
    var session: URLSession = .shared

    enum ClientError: Error { case badResponse(Int), malformed }

    func fetch(reportKey: String, start: Date, end: Date) async throws -> [LiveReportRow] {
        var comps = URLComponents(string: "https://r.applovin.com/maxReport")!
        let df = ISO8601DateFormatter(); df.formatOptions = [.withFullDate]
        comps.queryItems = [
            .init(name: "api_key", value: reportKey),
            .init(name: "start", value: df.string(from: start)),
            .init(name: "end", value: df.string(from: end)),
            .init(name: "format", value: "json"),
            .init(name: "columns",
                  value: "day,application,package_name,platform,country,ad_format,impressions,estimated_revenue,ecpm,clicks"),
        ]
        var req = URLRequest(url: comps.url!)
        req.timeoutInterval = 30
        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw ClientError.malformed }
        guard (200..<300).contains(http.statusCode) else { throw ClientError.badResponse(http.statusCode) }

        let parsed = try JSONSerialization.jsonObject(with: data)
        guard let dict = parsed as? [String: Any],
              let results = dict["results"] as? [[String: Any]] else { throw ClientError.malformed }

        let dayFmt = DateFormatter()
        dayFmt.locale = Locale(identifier: "en_US_POSIX")
        dayFmt.dateFormat = "yyyy-MM-dd"

        return results.compactMap { r in
            guard let dayStr = r["day"] as? String, let date = dayFmt.date(from: dayStr) else { return nil }
            let impressions = Self.double(r["impressions"])
            let revenue = Self.double(r["estimated_revenue"])
            let clicks = Self.double(r["clicks"])
            return LiveReportRow(
                date: date, networkID: "applovin",
                appID: (r["package_name"] as? String) ?? (r["application"] as? String) ?? "app",
                appName: (r["application"] as? String) ?? "App",
                platform: (r["platform"] as? String)?.capitalized ?? "",
                country: (r["country"] as? String) ?? "",
                adFormat: (r["ad_format"] as? String) ?? "",
                earnings: revenue, impressions: impressions, clicks: clicks,
                requests: impressions, matched: impressions)  // MAX report has no request funnel → assume matched
        }
    }

    private static func double(_ any: Any?) -> Double {
        if let d = any as? Double { return d }
        if let i = any as? Int { return Double(i) }
        if let s = any as? String { return Double(s) ?? 0 }
        return 0
    }
}
