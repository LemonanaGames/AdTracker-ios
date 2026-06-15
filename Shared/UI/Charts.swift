import SwiftUI

struct BarDatum: Identifiable, Hashable {
    let id = UUID()
    let value: Double
    var dim: Bool = false
}

/// Proportional bar chart with rounded bars + optional labels (port of `BarChart`).
/// `dim` bars (today/partial) render in the muted `card2` color.
struct BarChart: View {
    @Environment(\.theme) private var t
    let data: [BarDatum]
    var labels: [String]? = nil
    var height: CGFloat = 150
    @State private var appeared = false

    init(data: [BarDatum], labels: [String]? = nil, height: CGFloat = 150) {
        self.data = data; self.labels = labels; self.height = height
    }

    var body: some View {
        let maxV = max(data.map(\.value).max() ?? 1, 1)
        VStack(spacing: 8) {
            HStack(alignment: .bottom, spacing: 0) {
                ForEach(Array(data.enumerated()), id: \.element.id) { i, d in
                    let h = max(2.5, d.value / maxV * height)
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(d.dim ? AnyShapeStyle(t.card2) : AnyShapeStyle(t.gradient))
                        .frame(height: appeared ? h : 0)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 1.8)
                        .animation(.spring(response: 0.6, dampingFraction: 0.85).delay(Double(i) * 0.03), value: appeared)
                }
            }
            .frame(height: height, alignment: .bottom)

            if let labels {
                HStack(spacing: 0) {
                    ForEach(Array(labels.enumerated()), id: \.offset) { _, label in
                        Text(label)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(t.ter)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .onAppear { appeared = true }
    }
}

/// Smooth area sparkline tinted by the accent (port of `Sparkline`).
struct Sparkline: View {
    @Environment(\.theme) private var t
    let data: [Double]
    var height: CGFloat = 32
    var lineWidth: CGFloat = 2

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let maxV = max(data.max() ?? 1, 1)
            let minV = data.min() ?? 0
            let range = maxV - minV == 0 ? 1 : maxV - minV
            let pts: [CGPoint] = data.enumerated().map { i, v in
                let x = data.count <= 1 ? 0 : CGFloat(i) / CGFloat(data.count - 1) * w
                let y = h - CGFloat((v - minV) / range) * (h - 4) - 2
                return CGPoint(x: x, y: y)
            }
            ZStack {
                // area fill
                Path { p in
                    guard let first = pts.first else { return }
                    p.move(to: first)
                    pts.dropFirst().forEach { p.addLine(to: $0) }
                    p.addLine(to: CGPoint(x: w, y: h))
                    p.addLine(to: CGPoint(x: 0, y: h))
                    p.closeSubpath()
                }
                .fill(LinearGradient(colors: [t.accent.opacity(0.28), t.accent.opacity(0)],
                                     startPoint: .top, endPoint: .bottom))
                // line
                Path { p in
                    guard let first = pts.first else { return }
                    p.move(to: first)
                    pts.dropFirst().forEach { p.addLine(to: $0) }
                }
                .stroke(t.accent, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            }
        }
        .frame(height: height)
    }
}
