import SwiftUI

/// Edit goal sheet — stepper + slider (port of `EditGoal`).
struct EditGoalSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.theme) private var t
    @Environment(\.dismiss) private var dismiss
    let mode: ReportMode

    @State private var val: Double = 0
    @State private var maxValue: Double = 1

    private var step: Double {
        switch mode {
        case .daily: 250
        case .weekly: 1000
        case .monthly: 5000
        case .yearly: 50000
        }
    }

    var body: some View {
        SheetScaffold(title: "Edit goal") {
            VStack(spacing: 0) {
                Text("\(mode.label) goal").font(.system(size: 15)).foregroundStyle(t.sec)
                    .textCase(.none).padding(.top, 10)
                Text(Format.money(val, dp: 0))
                    .font(.system(size: 56, weight: .heavy)).foregroundStyle(t.text)
                    .minimumScaleFactor(0.5).lineLimit(1)
                    .padding(.vertical, 14)

                HStack(spacing: 18) {
                    stepButton("minus") { val = max(step, val - step) }
                    Text("±\(Format.moneyK(step))").font(.system(size: 14)).foregroundStyle(t.ter).frame(minWidth: 90)
                    stepButton("plus") { val += step }
                }
                .padding(.bottom, 28)

                Slider(value: $val, in: step...max(maxValue, step * 2), step: step).tint(t.accent)
                    .padding(.bottom, 28)

                BigButton(title: "Save goal") {
                    model.goals[mode] = val
                    dismiss()
                }
            }
            .padding(.horizontal, 20).padding(.bottom, 28)
        }
        .onAppear {
            val = model.goals[mode]
            maxValue = model.goals[mode] * 3
        }
    }

    private func stepButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: 22, weight: .regular)).foregroundStyle(t.text)
                .frame(width: 52, height: 52).background(t.card2, in: Circle())
        }
        .buttonStyle(.plain)
    }
}
