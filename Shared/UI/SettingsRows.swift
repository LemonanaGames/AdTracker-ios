import SwiftUI

/// A grouped settings card with an optional uppercase header (port of `Group`).
struct SettingsGroup<Content: View>: View {
    @Environment(\.theme) private var t
    var header: String? = nil
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            if let header {
                Text(header.uppercased())
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(t.sec)
                    .padding(.horizontal, 20)
            }
            Card(padding: 0) { VStack(spacing: 0) { content } }
        }
        .padding(.bottom, 20)
    }
}

/// A single settings row (port of `Row`).
struct SettingsRow: View {
    @Environment(\.theme) private var t
    var symbol: String? = nil
    var iconBg: Color? = nil
    var title: String
    var sub: String? = nil
    var detail: String? = nil
    var first: Bool = false
    var trailing: AnyView? = nil
    var onTap: (() -> Void)? = nil

    var body: some View {
        let row = HStack(spacing: 12) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(iconBg ?? t.accent, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.system(size: 15.5, weight: .medium)).foregroundStyle(t.text)
                if let sub { Text(sub).font(.system(size: 12.5)).foregroundStyle(t.ter) }
            }
            Spacer(minLength: 4)
            if let detail { Text(detail).font(.system(size: 14.5)).foregroundStyle(t.sec) }
            if let trailing {
                trailing
            } else if onTap != nil {
                Image(systemName: Sym.chevron).font(.system(size: 13, weight: .semibold)).foregroundStyle(t.ter)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .contentShape(Rectangle())

        VStack(spacing: 0) {
            if !first { Divider().overlay(t.hair) }
            if let onTap {
                Button(action: onTap) { row }.buttonStyle(.plain)
            } else {
                row
            }
        }
    }
}
