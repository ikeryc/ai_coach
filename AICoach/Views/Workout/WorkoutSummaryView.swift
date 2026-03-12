import SwiftUI

struct WorkoutSummaryView: View {

    let viewModel: WorkoutSessionViewModel
    let onDismiss: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(.green)
                        Text("¡Sesión completada!")
                            .font(.title2.bold())
                        Text(viewModel.sessionName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 16)

                    // Estadísticas principales
                    HStack(spacing: 12) {
                        SummaryStatCard(
                            icon: "clock.fill",
                            value: viewModel.elapsedDisplay,
                            label: "Duración",
                            color: .blue
                        )
                        SummaryStatCard(
                            icon: "scalemass.fill",
                            value: String(format: "%.0f kg", viewModel.totalVolume),
                            label: "Volumen total",
                            color: .orange
                        )
                        SummaryStatCard(
                            icon: "list.number",
                            value: "\(viewModel.totalCompletedSets)",
                            label: "Sets",
                            color: .purple
                        )
                    }

                    // PRs detectados
                    if !viewModel.detectedPRs.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Nuevos récords personales", systemImage: "trophy.fill")
                                .font(.headline)
                                .foregroundStyle(.yellow)

                            ForEach(viewModel.detectedPRs) { pr in
                                HStack {
                                    Image(systemName: "star.fill")
                                        .foregroundStyle(.yellow)
                                        .font(.caption)
                                    Text(pr.exerciseName)
                                        .font(.subheadline.weight(.semibold))
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 1) {
                                        Text(String(format: "%.1f kg e1RM", pr.newE1RM))
                                            .font(.subheadline.bold())
                                            .foregroundStyle(.green)
                                        if let prev = pr.previousE1RM {
                                            Text(String(format: "+%.1f kg", pr.newE1RM - prev))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        } else {
                                            Text("Primer registro")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                .padding(12)
                                .background(Color.yellow.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                        .padding(16)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    // Resumen por ejercicio
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Por ejercicio")
                            .font(.headline)

                        ForEach(viewModel.activeExercises.filter { !$0.completedSets.isEmpty }) { activeEx in
                            ExerciseSummaryRow(activeExercise: activeEx)
                        }
                    }
                    .padding(16)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    Spacer(minLength: 20)
                }
                .padding(.horizontal)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Listo") {
                        dismiss()
                        onDismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .interactiveDismissDisabled()
    }
}

// MARK: - Subviews

private struct SummaryStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.headline)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct ExerciseSummaryRow: View {
    let activeExercise: ActiveExercise

    var bestSet: ActiveSet? {
        activeExercise.completedSets
            .filter { !$0.isWarmup }
            .max { Formulas.epley(weight: $0.weightKg, reps: $0.reps) < Formulas.epley(weight: $1.weightKg, reps: $1.reps) }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(activeExercise.exercise.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text("\(activeExercise.completedSets.filter { !$0.isWarmup }.count) sets · \(String(format: "%.0f kg", activeExercise.totalVolume)) vol.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let best = bestSet {
                Text("\(String(format: "%.1f", best.weightKg)) × \(best.reps)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.blue)
            }
        }
    }
}
