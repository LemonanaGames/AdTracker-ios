import Foundation

/// Google AdMob API client (REST v1).
/// Docs: https://developers.google.com/admob/api/v1/reference/rest/v1/accounts.networkReport/generate
///
/// Auth: an OAuth2 access token with scope `https://www.googleapis.com/auth/admob.readonly`
/// (see `AdMobAuth`). Confirm metric/dimension enum names against your account.
struct AdMobClient {
    var session: URLSession = .shared
    enum ClientError: Error { case badResponse(Int), malformed, noPublisher }

    /// Resolve the publisher account id (`pub-…`) for the signed-in Google account.
    func publisherID(accessToken: String) async throws -> String {
        var req = URLRequest(url: URL(string: "https://admob.googleapis.com/v1/accounts")!)
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ClientError.badResponse((resp as? HTTPURLResponse)?.statusCode ?? -1)
        }
        guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let accounts = dict["account"] as? [[String: Any]],
              let name = accounts.first?["name"] as? String else { throw ClientError.noPublisher }
        // name is "accounts/pub-XXXXXXXX"
        return name.replacingOccurrences(of: "accounts/", with: "")
    }

    func fetch(accessToken: String, publisherID: String, start: Date, end: Date) async throws -> [LiveReportRow] {
        let url = URL(string: "https://admob.googleapis.com/v1/accounts/\(publisherID)/networkReport:generate")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: Self.body(start: start, end: end))

        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw ClientError.malformed }
        guard (200..<300).contains(http.statusCode) else { throw ClientError.badResponse(http.statusCode) }

        // Response is a JSON array: [ {header}, {row}, {row}, …, {footer} ]
        guard let arr = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { throw ClientError.malformed }
        let df = DateFormatter(); df.locale = Locale(identifier: "en_US_POSIX"); df.dateFormat = "yyyyMMdd"

        return arr.compactMap { entry -> LiveReportRow? in
            guard let row = entry["row"] as? [String: Any],
                  let dims = row["dimensionValues"] as? [String: Any],
                  let mets = row["metricValues"] as? [String: Any] else { return nil }
            let dateStr = (dims["DATE"] as? [String: Any])?["value"] as? String ?? ""
            guard let date = df.date(from: dateStr) else { return nil }
            return LiveReportRow(
                date: date, networkID: "admob",
                appID: value(dims["APP"]) ?? "app",
                appName: label(dims["APP"]) ?? "App",
                platform: "",
                country: value(dims["COUNTRY"]) ?? "",
                adFormat: value(dims["FORMAT"]) ?? "",
                earnings: micros(mets["ESTIMATED_EARNINGS"]),
                impressions: integer(mets["IMPRESSIONS"]),
                clicks: integer(mets["CLICKS"]),
                requests: integer(mets["AD_REQUESTS"]),
                matched: integer(mets["MATCHED_REQUESTS"]))
        }
    }

    private static func body(start: Date, end: Date) -> [String: Any] {
        func ymd(_ d: Date) -> [String: Int] {
            let c = Calendar.current.dateComponents([.year, .month, .day], from: d)
            return ["year": c.year!, "month": c.month!, "day": c.day!]
        }
        return ["reportSpec": [
            "dateRange": ["startDate": ymd(start), "endDate": ymd(end)],
            "dimensions": ["DATE", "APP", "COUNTRY", "FORMAT"],
            "metrics": ["ESTIMATED_EARNINGS", "IMPRESSIONS", "CLICKS", "AD_REQUESTS", "MATCHED_REQUESTS"],
        ]]
    }

    // metric/dimension value helpers
    private func value(_ any: Any?) -> String? { (any as? [String: Any])?["value"] as? String }
    private func label(_ any: Any?) -> String? { (any as? [String: Any])?["displayLabel"] as? String }
    private func integer(_ any: Any?) -> Double {
        guard let v = (any as? [String: Any])?["integerValue"] else { return 0 }
        if let s = v as? String { return Double(s) ?? 0 }
        if let i = v as? Int { return Double(i) }
        return (v as? Double) ?? 0
    }
    private func micros(_ any: Any?) -> Double {
        guard let v = (any as? [String: Any])?["microsValue"] else { return 0 }
        let micros: Double
        if let s = v as? String { micros = Double(s) ?? 0 }
        else if let i = v as? Int { micros = Double(i) }
        else { micros = (v as? Double) ?? 0 }
        return micros / 1_000_000
    }
}
