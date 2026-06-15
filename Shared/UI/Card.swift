import SwiftUI

/// Rounded surface container (port of the design's `Card`).
struct Card<Content: View>: View {
    @Environment(\.theme) private var t
    var padding: CGFloat = 16
    var cornerRadius: CGFloat = 22
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(t.card, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: t.dark ? .clear : .black.opacity(0.04), radius: 1, y: 1)
    }
}

extension View {
    /// Tappable card press feedback that matches the design's hover/press affordance.
    func cardTap(_ action: @escaping () -> Void) -> some View {
        Button(action: action) { self }
            .buttonStyle(CardButtonStyle())
    }
}

private struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
