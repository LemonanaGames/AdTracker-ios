import SwiftUI

/// Network monogram tile (port of `NetBadge`) — generic mark, not a brand logo.
struct NetBadge: View {
    let network: AdNetwork
    var size: CGFloat = 38
    var radius: CGFloat? = nil

    private var grad: [Color] {
        network.id == "applovin" ? [Color(hex: "#8b6df7"), Color(hex: "#5b6df5")]
                                  : [Color(hex: "#4aa863"), Color(hex: "#2e8b48")]
    }
    private var letter: String { network.id == "applovin" ? "A" : "G" }

    var body: some View {
        Text(letter)
            .font(.system(size: size * 0.5, weight: .heavy))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(LinearGradient(colors: grad, startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: RoundedRectangle(cornerRadius: radius ?? size * 0.28, style: .continuous))
            .shadow(color: grad[1].opacity(0.27), radius: 6, y: 4)
    }
}

/// Hue-derived app icon tile (port of `AppIcon`).
struct AppIconTile: View {
    let app: MonetizedApp
    var size: CGFloat = 42
    var radius: CGFloat? = nil

    private func color(_ brightness: Double) -> Color {
        Color(hue: app.hue / 360, saturation: 0.7, brightness: brightness)
    }

    var body: some View {
        Text(String(app.name.prefix(1)))
            .font(.system(size: size * 0.46, weight: .heavy))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(LinearGradient(colors: [color(0.85), color(0.55)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: RoundedRectangle(cornerRadius: radius ?? size * 0.26, style: .continuous))
            .shadow(color: color(0.6).opacity(0.4), radius: 6, y: 4)
    }
}

/// Country flag tile (port of `FlagTile`).
struct FlagTile: View {
    @Environment(\.theme) private var t
    let flag: String
    var size: CGFloat = 38
    var body: some View {
        Text(flag)
            .font(.system(size: size * 0.55))
            .frame(width: size, height: size)
            .background(t.card2, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

/// Ad-unit tile (port of `UnitTile`).
struct UnitTile: View {
    @Environment(\.theme) private var t
    var size: CGFloat = 38
    var body: some View {
        Image(systemName: Sym.layers)
            .font(.system(size: size * 0.46))
            .foregroundStyle(t.accent)
            .frame(width: size, height: size)
            .background(t.accentSoft, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

/// Renders a `BreakdownRow.Lead`.
struct LeadView: View {
    let lead: BreakdownRow.Lead
    var size: CGFloat = 38
    var body: some View {
        switch lead {
        case .app(let a): AppIconTile(app: a, size: size)
        case .network(let n): NetBadge(network: n, size: size)
        case .flag(let f): FlagTile(flag: f, size: size)
        case .unit: UnitTile(size: size)
        }
    }
}
