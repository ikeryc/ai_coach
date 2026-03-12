import SwiftUI

struct OnboardingCompleteView: View {

    let viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tu plan está listo")
                        .font(.largeTitle.bold())
                    Text("Basado en tus datos hemos calculado tus objetivos iniciales. Puedes ajustarlos en cualquier momento.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Resumen de perfil
                VStack(spacing: 12) {
                    SummaryRow(label: "Objetivo", value: viewModel.primaryGoal.displayName, icon: "target")
                    SummaryRow(label: "Nivel", value: viewModel.experienceLevel.displayName, icon: "chart.bar.fill")
                    SummaryRow(label: "Días/semana", value: "\(viewModel.availableTrainingDays) días", icon: "calendar")
                    SummaryRow(label: "Equipamiento", value: viewModel.equipment.displayName, icon: "dumbbell.fill")
                }
                .padding(16)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // Objetivos nutricionales calculados
                VStack(alignment: .leading, spacing: 12) {
                    Text("Objetivos nutricionales")
                        .font(.headline)

                    HStack(spacing: 12) {
                        MacroSummaryCard(
                            label: "Calorías",
                            value: "\(viewModel.recommendedCalories)",
                            unit: "kcal",
                            color: .orange
                        )
                        MacroSummaryCard(
                            label: "Proteína",
                            value: "\(viewModel.recommendedProtein)",
                            unit: "g",
                            color: .blue
                        )
                    }

                    Text("Calculado con TDEE ≈ \(viewModel.tdeeEstimate) kcal usando fórmula Mifflin-St Jeor.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Qué pasa después
                VStack(alignment: .leading, spacing: 10) {
                    Text("Próximos pasos")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 8) {
                        NextStepRow(number: 1, text: "Explora la biblioteca de \u{007E}800 ejercicios")
                        NextStepRow(number: 2, text: "Crea o genera con IA tu primer programa")
                        NextStepRow(number: 3, text: "Registra tu primer entrenamiento")
                        NextStepRow(number: 4, text: "Sigue tu progreso semana a semana")
                    }
                }
                .padding(16)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding()
                        .background(Color.red.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Spacer(minLength: 20)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
        }
    }
}

// MARK: - Subviews

private struct SummaryRow: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.blue)
                .frame(width: 22)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
        }
    }
}

private struct MacroSummaryCard: View {
    let label: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(unit)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(label)
                .font(.caption.weight(.medium))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct NextStepRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Text("\(number)")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(Color.blue)
                .clipShape(Circle())

            Text(text)
                .font(.subheadline)
        }
    }
}
