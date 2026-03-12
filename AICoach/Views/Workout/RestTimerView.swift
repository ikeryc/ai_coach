import SwiftUI

struct RestTimerView: View {

    @Bindable var viewModel: WorkoutSessionViewModel
    @State private var showSettings = false

    private let presets = [60, 90, 120, 180, 240]

    var progress: Double {
        guard viewModel.restTimerTarget > 0 else { return 0 }
        return Double(viewModel.restTimerSeconds) / Double(viewModel.restTimerTarget)
    }

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color(.tertiarySystemFill))
                .frame(width: 36, height: 4)
                .padding(.top, 8)

            HStack(spacing: 16) {
                // Barra de progreso circular compacta
                ZStack {
                    Circle()
                        .stroke(Color(.tertiarySystemFill), lineWidth: 4)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(timerColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: progress)
                }
                .frame(width: 44, height: 44)
                .overlay {
                    Text(formatSeconds(viewModel.restTimerSeconds))
                        .font(.caption.monospacedDigit().weight(.semibold))
                        .foregroundStyle(timerColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Descansando")
                        .font(.subheadline.weight(.semibold))
                    Text("Objetivo: \(formatSeconds(viewModel.restTimerTarget))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Presets rápidos
                HStack(spacing: 6) {
                    ForEach([60, 90, 120], id: \.self) { secs in
                        Button("\(secs/60)m") {
                            viewModel.restTimerTarget = secs
                            viewModel.startRestTimer(seconds: secs)
                        }
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(viewModel.restTimerTarget == secs ? Color.blue : Color(.tertiarySystemFill))
                        .foregroundStyle(viewModel.restTimerTarget == secs ? .white : .secondary)
                        .clipShape(Capsule())
                    }
                }

                Button {
                    viewModel.stopRestTimer()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.12), radius: 8, y: -2)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    private var timerColor: Color {
        if progress > 0.5 { return .green }
        if progress > 0.2 { return .orange }
        return .red
    }

    private func formatSeconds(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
