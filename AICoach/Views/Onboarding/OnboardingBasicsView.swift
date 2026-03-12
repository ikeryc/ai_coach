import SwiftUI

struct OnboardingBasicsView: View {

    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                OnboardingHeader(
                    title: viewModel.currentStep.title,
                    subtitle: "Esta información nos ayuda a calcular tus necesidades calóricas y adaptar tu programa."
                )

                // Sexo
                VStack(alignment: .leading, spacing: 12) {
                    Text("Sexo biológico")
                        .font(.headline)

                    HStack(spacing: 12) {
                        ForEach(Sex.allCases, id: \.self) { sex in
                            SexButton(
                                sex: sex,
                                isSelected: viewModel.sex == sex,
                                action: { viewModel.sex = sex }
                            )
                        }
                    }
                }

                // Edad
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Edad")
                            .font(.headline)
                        Spacer()
                        Text("\(viewModel.age) años")
                            .font(.headline)
                            .foregroundStyle(.blue)
                    }

                    Slider(value: Binding(
                        get: { Double(viewModel.age) },
                        set: { viewModel.age = Int($0) }
                    ), in: 13...80, step: 1)
                    .tint(.blue)

                    HStack {
                        Text("13").font(.caption).foregroundStyle(.secondary)
                        Spacer()
                        Text("80").font(.caption).foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 20)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
        }
    }
}

// MARK: - Subviews

private struct SexButton: View {
    let sex: Sex
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: sex == .male ? "figure.stand" : sex == .female ? "figure.stand.dress" : "person.fill")
                    .font(.title)
                Text(sex.displayName)
                    .font(.subheadline.weight(.medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(isSelected ? Color.blue.opacity(0.15) : Color(.secondarySystemGroupedBackground))
            .foregroundStyle(isSelected ? .blue : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
