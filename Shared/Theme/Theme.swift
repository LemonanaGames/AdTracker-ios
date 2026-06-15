import SwiftUI

/// A flat color-token set — the SwiftUI port of the three directions in `theme.jsx`.
struct Theme: Equatable, Sendable {
    var key: String
    var label: String
    var dark: Bool

    var bg: Color
    var bg2: Color
    var card: Color
    var card2: Color
    var hair: Color
    var text: Color
    var sec: Color
    var ter: Color
    var accent: Color
    var accentText: Color
    var accentSoft: Color
    var grad: [Color]
    var pos: Color
    var neg: Color
    var tabActive: Color

    /// Whether the tab-bar active tint follows the accent (so accent overrides apply to it).
    var tabActiveFollowsAccent: Bool

    var gradient: LinearGradient {
        LinearGradient(colors: grad, startPoint: .top, endPoint: .bottom)
    }
    var gradientH: LinearGradient {
        LinearGradient(colors: grad, startPoint: .leading, endPoint: .trailing)
    }
}

extension Theme {
    // 1. Midnight — near-black + teal (reference-inspired, default)
    static let midnight = Theme(
        key: "midnight", label: "Midnight", dark: true,
        bg: Color(hex: "#000000"), bg2: Color(hex: "#0c0d0f"),
        card: Color(hex: "#1a1c1e"), card2: Color(hex: "#242629"),
        hair: .rgba(255, 255, 255, 0.08),
        text: Color(hex: "#ffffff"), sec: .rgba(235, 235, 245, 0.62), ter: .rgba(235, 235, 245, 0.32),
        accent: Color(hex: "#5cb7c9"), accentText: Color(hex: "#062227"), accentSoft: .rgba(92, 183, 201, 0.16),
        grad: [Color(hex: "#67c3d4"), Color(hex: "#3f95a6")],
        pos: Color(hex: "#4cc38a"), neg: Color(hex: "#ff6b6b"), tabActive: Color(hex: "#5cb7c9"),
        tabActiveFollowsAccent: true)

    // 2. Graphite — monochrome + lime
    static let graphite = Theme(
        key: "graphite", label: "Graphite", dark: true,
        bg: Color(hex: "#0a0a0b"), bg2: Color(hex: "#121214"),
        card: Color(hex: "#1c1c1f"), card2: Color(hex: "#27272b"),
        hair: .rgba(255, 255, 255, 0.07),
        text: Color(hex: "#f5f5f7"), sec: .rgba(235, 235, 245, 0.6), ter: .rgba(235, 235, 245, 0.3),
        accent: Color(hex: "#a3e635"), accentText: Color(hex: "#14210a"), accentSoft: .rgba(163, 230, 53, 0.14),
        grad: [Color(hex: "#bef264"), Color(hex: "#84cc16")],
        pos: Color(hex: "#a3e635"), neg: Color(hex: "#ff6b6b"), tabActive: Color(hex: "#f5f5f7"),
        tabActiveFollowsAccent: false)

    // 3. Mist — light premium, off-white + indigo
    static let mist = Theme(
        key: "mist", label: "Mist (Light)", dark: false,
        bg: Color(hex: "#f4f4f6"), bg2: Color(hex: "#ececed"),
        card: Color(hex: "#ffffff"), card2: Color(hex: "#f3f3f5"),
        hair: .rgba(60, 60, 67, 0.1),
        text: Color(hex: "#16161a"), sec: .rgba(60, 60, 67, 0.6), ter: .rgba(60, 60, 67, 0.32),
        accent: Color(hex: "#5b5bf0"), accentText: Color(hex: "#ffffff"), accentSoft: .rgba(91, 91, 240, 0.1),
        grad: [Color(hex: "#6d6df5"), Color(hex: "#4a4ad8")],
        pos: Color(hex: "#1f9d57"), neg: Color(hex: "#e5484d"), tabActive: Color(hex: "#5b5bf0"),
        tabActiveFollowsAccent: true)

    static let all = [midnight, graphite, mist]
    static func named(_ key: String) -> Theme { all.first { $0.key == key } ?? midnight }

    /// Default accent hex for each direction (used by the accent picker as "system").
    var defaultAccentHex: String {
        switch key {
        case "graphite": "#a3e635"
        case "mist": "#5b5bf0"
        default: "#5cb7c9"
        }
    }

    /// Accent override palette offered in Settings → Appearance.
    static let accentPalette = ["#5cb7c9", "#7b5bf5", "#4cc38a", "#ff9f43", "#5b5bf0"]

    /// Returns a copy with the accent (and derived tokens) replaced (matches `applyAccent`).
    func applyingAccent(_ hex: String?) -> Theme {
        guard let hex, hex != "default", hex != defaultAccentHex else { return self }
        var t = self
        let accent = Color(hex: hex)
        t.accent = accent
        t.grad = [accent, HexColor.shade(hex, -0.18)]
        t.accentSoft = HexColor.alpha(hex, dark ? 0.16 : 0.10)
        if tabActiveFollowsAccent { t.tabActive = accent }
        return t
    }
}
