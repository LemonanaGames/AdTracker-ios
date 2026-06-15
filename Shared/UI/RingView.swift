import SwiftUI

/// Circular progress ring with centered content (port of `Ring`).
struct RingView<Content: View>: View {
    @Environment(\.theme) private var t
    let value: Double
    let goal: Double
    var size: CGFloat = 160
    var lineWidth: CGFloat = 14
    var color: Color? = nil
    var track: Color? = nil
    var content: Content

    @State private var animated = false

    init(value: Double, goal: Double, size: CGFloat = 160, lineWidth: CGFloat = 14,
         color: Color? = nil, track: Color? = nil, @ViewBuilder content: () -> Content) {
        self.value = value; self.goal = goal; self.size = size; self.lineWidth = lineWidth
        self.color = color; self.track = track; self.content = content()
    }

    var body: some View {
        let pct = max(0, min(1, goal == 0 ? 0 : value / goal))
        ZStack {
            Circle()
                .stroke(track ?? t.card2, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: animated ? pct : 0)
                .stroke(color ?? t.accent, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 1.0, dampingFraction: 0.9), value: animated)
            content
        }
        .frame(width: size, height: size)
        .onAppear { animated = true }
    }
}

extension RingView where Content == EmptyView {
    init(value: Double, goal: Double, size: CGFloat = 160, lineWidth: CGFloat = 14,
         color: Color? = nil, track: Color? = nil) {
        self.init(value: value, goal: goal, size: size, lineWidth: lineWidth,
                  color: color, track: track) { EmptyView() }
    }
}
