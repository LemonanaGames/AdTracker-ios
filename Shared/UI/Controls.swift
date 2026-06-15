import SwiftUI

/// Inline segmented control (port of `Segmented`).
struct Segmented<T: Hashable & Identifiable>: View {
    @Environment(\.theme) private var t
    let options: [(T, String)]
    @Binding var selection: T
    var small = false

    var body: some View {
        HStack(spacing: 2) {
            ForEach(options, id: \.0.id) { opt in
                let sel = opt.0 == selection
                Button { withAnimation(.easeOut(duration: 0.18)) { selection = opt.0 } } label: {
                    Text(opt.1)
                        .font(.system(size: small ? 12.5 : 14, weight: .semibold))
                        .foregroundStyle(sel ? t.text : t.sec)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, small ? 6 : 8)
                        .background {
                            if sel {
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .fill(t.dark ? t.card : .white)
                                    .shadow(color: .black.opacity(0.12), radius: 1.5, y: 1)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(t.card2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

/// Horizontally scrollable pill tabs (port of `PillTabs`) — periods & metric selectors.
struct PillTabs<T: Hashable & Identifiable>: View {
    @Environment(\.theme) private var t
    let options: [(T, String)]
    @Binding var selection: T
    var small = false

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(options, id: \.0.id) { opt in
                    let sel = opt.0 == selection
                    Button { withAnimation(.easeOut(duration: 0.15)) { selection = opt.0 } } label: {
                        Text(opt.1)
                            .font(.system(size: small ? 13 : 14.5, weight: .semibold))
                            .foregroundStyle(sel ? t.bg : t.sec)
                            .padding(.horizontal, small ? 13 : 16)
                            .padding(.vertical, small ? 6 : 8)
                            .background(sel ? t.text : t.card, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2)
        }
    }
}

/// Up/down change chip (port of `Delta`).
struct DeltaChip: View {
    @Environment(\.theme) private var t
    let value: Double
    var sub: String? = nil

    var body: some View {
        let up = value >= 0
        let col = up ? t.pos : t.neg
        HStack(spacing: 3) {
            Image(systemName: up ? Sym.arrowUp : Sym.arrowDown)
                .font(.system(size: 11, weight: .heavy))
            Text(Format.pct(abs(value)))
                .font(.system(size: 13, weight: .bold))
            if let sub {
                Text(sub).font(.system(size: 13, weight: .medium)).foregroundStyle(t.ter)
            }
        }
        .foregroundStyle(col)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(col.opacity(0.13), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

/// Large section header with optional trailing action (port of `SectionTitle`).
struct SectionTitle: View {
    @Environment(\.theme) private var t
    let title: String
    var action: String? = nil
    var onAction: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(t.text)
            Spacer()
            if let action, let onAction {
                Button(action: onAction) {
                    Text(action).font(.system(size: 15, weight: .semibold)).foregroundStyle(t.accent)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 4)
    }
}

/// Full-width primary action button (port of `primaryBtn`).
struct BigButton: View {
    @Environment(\.theme) private var t
    let title: String
    var style: Style = .filled
    var leadingSymbol: String? = nil
    let action: () -> Void

    enum Style { case filled, tinted }   // tinted = card bg + accent text

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let leadingSymbol { Image(systemName: leadingSymbol).font(.system(size: 18, weight: .semibold)) }
                Text(title).font(.system(size: 17, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .foregroundStyle(style == .filled ? t.accentText : t.accent)
            .background(style == .filled ? AnyShapeStyle(t.accent) : AnyShapeStyle(t.card),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

/// A circular icon "pill" button used in toolbars (port of `iconPill`).
struct IconPill: View {
    @Environment(\.theme) private var t
    let symbol: String
    var tint: Color? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(tint ?? t.accent)
                .frame(width: 38, height: 38)
                .background(t.card, in: Circle())
        }
        .buttonStyle(.plain)
    }
}
