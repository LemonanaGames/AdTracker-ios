import SwiftUI

extension Color {
    /// Parses `#rgb`, `#rrggbb`, or `#rrggbbaa`.
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let r, g, b, a: Double
        switch h.count {
        case 3: // rgb
            r = Double((int >> 8) & 0xF) / 15; g = Double((int >> 4) & 0xF) / 15; b = Double(int & 0xF) / 15; a = 1
        case 8: // rrggbbaa
            r = Double((int >> 24) & 0xFF) / 255; g = Double((int >> 16) & 0xFF) / 255
            b = Double((int >> 8) & 0xFF) / 255; a = Double(int & 0xFF) / 255
        default: // rrggbb
            r = Double((int >> 16) & 0xFF) / 255; g = Double((int >> 8) & 0xFF) / 255; b = Double(int & 0xFF) / 255; a = 1
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }

    /// Translucent white/black-channel color (matches the design's `rgba(...)` tokens).
    static func rgba(_ r: Double, _ g: Double, _ b: Double, _ a: Double) -> Color {
        Color(.sRGB, red: r / 255, green: g / 255, blue: b / 255, opacity: a)
    }
}

enum HexColor {
    /// Lighten/darken a hex color by a fraction (matches `shade()` in main.jsx).
    static func shade(_ hex: String, _ amt: Double) -> Color {
        let c = components(hex)
        let shaded = c.map { v -> Double in
            min(255, max(0, (v + v * amt).rounded()))
        }
        return Color(.sRGB, red: shaded[0] / 255, green: shaded[1] / 255, blue: shaded[2] / 255, opacity: 1)
    }
    /// Hex color at a given alpha (matches `hexA()` in main.jsx).
    static func alpha(_ hex: String, _ a: Double) -> Color {
        let c = components(hex)
        return Color(.sRGB, red: c[0] / 255, green: c[1] / 255, blue: c[2] / 255, opacity: a)
    }
    private static func components(_ hex: String) -> [Double] {
        let h = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        return [Double((int >> 16) & 0xFF), Double((int >> 8) & 0xFF), Double(int & 0xFF)]
    }
}
