import SwiftUI

struct OnboardingGoalView: View {

    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                OnboardingHeader(
                    title: viewModel.currentStep.title,
                    subtitle: "Tu objetivo determina la distribución de macros, el superávit o déficit calórico, y la estructura de los programas."
                )

                VStack(spacing: 12) {
                    ForEach(TrainingGoal.allCases, id: \.self) { goal in
                        GoalCard(
                            goal: goal,
                            isSelected: viewModel.primaryGoal == goal,
                            action: { viewModel.primaryGoal = goal }
                        )
                    }
                }

                Spacer(minLength: 20)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
        }
    }
}

// MARK: - GoalCard

private struct GoalCard: View {
    let goal: TrainingGoal
    let isSelected: Bool
    let action: () -> Void

    var goalIcon: String {
        switch goal {
        case .hypertrophy: "figure.strengthtraining.traditional"
        case .strength: "bolt.fill"
        case .fatLoss: "flame.fill"
        case .recomposition: "arrow.triangle.2.circlepath"
        }
    }

    var goalColor: Color {
        switch goal {
        case .hypertrophy: .blue
        case .strength: .orange
        case .fatLoss: .red
        case .recomposition: .purple
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(goalColor.opacity(isSelected ? 0.2 : 0.1))
                        .frame(width: 52, height: 52)
                    Image(systemName: goalIcon)
                        .font(.title2)
                        .foregroundStyle(goalColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(goal.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(goal.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(goalColor)
                        .font(.title3)
                }
            }
            .padding(16)
            .background(isSelected ? goalColor.opacity(0.08) : Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? goalColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
