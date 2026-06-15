import Foundation
import AuthenticationServices
import CryptoKit
import UIKit

/// Fill these from your Google Cloud OAuth client (iOS type) before live AdMob sync works.
/// Until `clientID` is set, the app stays on cached/mock data.
enum AdMobConfig {
    /// e.g. "1234567890-abcdef.apps.googleusercontent.com"
    static let clientID = ""
    /// Reversed client id + ":/oauth2redirect" — also add the reversed id as a URL scheme in Info.plist.
    static var redirectURI: String {
        let reversed = clientID.split(separator: ".").reversed().joined(separator: ".")
        return "\(reversed):/oauth2redirect"
    }
    static let scope = "https://www.googleapis.com/auth/admob.readonly"
    static var isConfigured: Bool { !clientID.isEmpty }
}

/// Minimal Google OAuth2 (auth-code + PKCE) using ASWebAuthenticationSession.
/// Stores the refresh token in the Keychain and vends fresh access tokens.
@MainActor
final class AdMobAuth: NSObject, ASWebAuthenticationPresentationContextProviding {

    enum AuthError: Error { case notConfigured, cancelled, tokenExchange }

    private var cachedAccessToken: String?
    private var accessTokenExpiry: Date?
    private let refreshKey = "admob.refresh.global"

    var isSignedIn: Bool { Keychain.get(refreshKey) != nil }

    /// Interactive sign-in; persists a refresh token on success.
    func signIn() async throws {
        guard AdMobConfig.isConfigured else { throw AuthError.notConfigured }
        let verifier = Self.randomURLSafe(64)
        let challenge = Self.codeChallenge(verifier)
        var comps = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")!
        comps.queryItems = [
            .init(name: "client_id", value: AdMobConfig.clientID),
            .init(name: "redirect_uri", value: AdMobConfig.redirectURI),
            .init(name: "response_type", value: "code"),
            .init(name: "scope", value: AdMobConfig.scope),
            .init(name: "code_challenge", value: challenge),
            .init(name: "code_challenge_method", value: "S256"),
            .init(name: "access_type", value: "offline"),
            .init(name: "prompt", value: "consent"),
        ]
        let scheme = String(AdMobConfig.redirectURI.split(separator: ":").first ?? "")
        let callbackURL: URL = try await withCheckedThrowingContinuation { cont in
            let session = ASWebAuthenticationSession(url: comps.url!, callbackURLScheme: scheme) { url, error in
                if let url { cont.resume(returning: url) }
                else { cont.resume(throwing: error ?? AuthError.cancelled) }
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            if !session.start() { cont.resume(throwing: AuthError.cancelled) }
        }
        guard let code = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?
            .queryItems?.first(where: { $0.name == "code" })?.value else { throw AuthError.cancelled }
        try await exchange(code: code, verifier: verifier)
    }

    /// A valid access token, refreshing if needed.
    func accessToken() async throws -> String {
        if let tok = cachedAccessToken, let exp = accessTokenExpiry, exp > Date().addingTimeInterval(60) {
            return tok
        }
        guard AdMobConfig.isConfigured, let refresh = Keychain.get(refreshKey) else { throw AuthError.notConfigured }
        let params = [
            "client_id": AdMobConfig.clientID,
            "grant_type": "refresh_token",
            "refresh_token": refresh,
        ]
        let json = try await tokenRequest(params)
        guard let access = json["access_token"] as? String else { throw AuthError.tokenExchange }
        store(access: access, expiresIn: json["expires_in"] as? Double ?? 3000)
        return access
    }

    func signOut() { Keychain.delete(refreshKey); cachedAccessToken = nil; accessTokenExpiry = nil }

    // MARK: - internals
    private func exchange(code: String, verifier: String) async throws {
        let params = [
            "client_id": AdMobConfig.clientID,
            "grant_type": "authorization_code",
            "code": code,
            "code_verifier": verifier,
            "redirect_uri": AdMobConfig.redirectURI,
        ]
        let json = try await tokenRequest(params)
        if let refresh = json["refresh_token"] as? String { Keychain.set(refresh, for: refreshKey) }
        if let access = json["access_token"] as? String {
            store(access: access, expiresIn: json["expires_in"] as? Double ?? 3000)
        }
    }

    private func tokenRequest(_ params: [String: String]) async throws -> [String: Any] {
        var req = URLRequest(url: URL(string: "https://oauth2.googleapis.com/token")!)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        req.httpBody = params.map { "\($0)=\($1.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? $1)" }
            .joined(separator: "&").data(using: .utf8)
        let (data, _) = try await URLSession.shared.data(for: req)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { throw AuthError.tokenExchange }
        return json
    }

    private func store(access: String, expiresIn: Double) {
        cachedAccessToken = access
        accessTokenExpiry = Date().addingTimeInterval(expiresIn)
    }

    // PKCE helpers
    private static func randomURLSafe(_ count: Int) -> String {
        var bytes = [UInt8](repeating: 0, count: count)
        _ = SecRandomCopyBytes(kSecRandomDefault, count, &bytes)
        return Data(bytes).base64URLEncoded()
    }
    private static func codeChallenge(_ verifier: String) -> String {
        Data(SHA256.hash(data: Data(verifier.utf8))).base64URLEncoded()
    }

    nonisolated func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            UIApplication.shared.connectedScenes
                .compactMap { ($0 as? UIWindowScene)?.keyWindow }
                .first ?? ASPresentationAnchor()
        }
    }
}

extension Data {
    func base64URLEncoded() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
