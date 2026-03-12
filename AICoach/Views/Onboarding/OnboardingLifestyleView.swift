import SwiftUI

struct OnboardingLifestyleView: View {

    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                OnboardingHeader(
                    title: viewModel.currentStep.title,
                    subtitle: "Ajustamos el volumen, la selección de ejercicios y la complejidad del programa a tu situación real."
                )

                // Nivel de experiencia
                VStack(alignment: .leading, spacing: 12) {
                    Text("Nivel de experiencia")
                        .font(.headline)

                    VStack(spacing: 8) {
                        ForEach(ExperienceLevel.allCases, id: \.self) { level in
                            ExperienceLevelRow(
                                level: level,
                                isSelected: viewModel.experienceLevel == level,
                                action: { viewModel.experienceLevel = level }
                            )
                        }
                    }
                }

                // Días disponibles
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Días de entrenamiento por semana")
                            .font(.headline)
                        Spacer()
                        Text("\(viewModel.availableTrainingDays) días")
                            .font(.headline)
                            .foregroundStyle(.blue)
                    }

                    Slider(value: Binding(
                        get: { Double(viewModel.availableTrainingDays) },
                        set: { viewModel.availableTrainingDays = Int($0) }
                    ), in: 2...6, step: 1)
                    .tint(.blue)

                    HStack {
                        ForEach(2...6, id: \.self) { day in
                            Text("\(day)")
                                .font(.caption)
                                .foregroundStyle(viewModel.availableTrainingDays == day ? .blue : .secondary)
                                .frame(maxWidth: .infinity)
                        }
                    }

                    // Recomendación de split
                    Text(splitRecommendation)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)
                }

                // Equipamiento
                VStack(alignment: .leading, spacing: 12) {
                    Text("Equipamiento disponible")
                        .font(.headline)

                    VStack(spacing: 8) {
                        ForEach(Equipment.allCases, id: \.self) { eq in
                            EquipmentRow(
                                equipment: eq,
                                isSelected: viewModel.equipment == eq,
                                action: { viewModel.equipment = eq }
                            )
                        }
                    }
                }

                Spacer(minLength: 20)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
        }
    }

    private var splitRecommendation: String {
        switch viewModel.availableTrainingDays {
        case 2: "Recomendado: Full Body ×2"
        case 3: "Recomendado: Full Body ×3 o PPL comprimido"
        case 4: "Recomendado: Upper/Lower ×2"
        case 5: "Recomendado: PPL + Upper/Lower"
        case 6: "Recomendado: PPL ×2"
        default: "Selecciona un número de días"
        }
    }
}

// MARK: - Subviews

private struct ExperienceLevelRow: View {
    let level: ExperienceLevel
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Circle()
                    .fill(isSelected ? Color.blue : Color(.tertiarySystemFill))
                    .frame(width: 22, height: 22)
                    .overlay {
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                        }
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text(level.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(level.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(14)
            .background(isSelected ? Color.blue.opacity(0.08) : Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct EquipmentRow: View {
    let equipment: Equipment
    let isSelected: Bool
    let action: () -> Void

    var icon: String {
        switch equipment {
        case .fullGym: "building.2.fill"
        case .home: "house.fill"
        case .dumbbellsOnly: "dumbbell.fill"
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(isSelected ? .blue : .secondary)
                    .frame(width: 30)

                Text(equipment.displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                }
            }
            .padding(14)
            .background(isSelected ? Color.blue.opacity(0.08) : Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}
