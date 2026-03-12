import SwiftUI
import Charts

struct WorkoutDetailView: View {

    let session: TrainingSession

    private var exerciseGroups: [(exercise: Exercise, sets: [ExerciseSet])] {
        let workingSets = session.sets.filter { !$0.isWarmup }
        let grouped = Dictionary(grouping: workingSets) { set -> Exercise? in set.exercise }
        return grouped.compactMap { key, value in
            guard let exercise = key else { return nil }
            return (exercise: exercise, sets: value.sorted { $0.setNumber < $1.setNumber })
        }
        .sorted { $0.exercise.name < $1.exercise.name }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // Estadísticas resumen
                HStack(spacing: 12) {
                    DetailStatCard(
                        icon: "clock",
                        value: session.durationDisplay,
                        label: "Duración",
                        color: .blue
                    )
                    DetailStatCard(
                        icon: "scalemass",
                        value: String(format: "%.0f kg", session.totalVolume),
                        label: "Volumen",
                        color: .orange
                    )
                    DetailStatCard(
                        icon: "list.number",
                        value: "\(session.workingSets.count)",
                        label: "Sets",
                        color: .purple
                    )
                }

                if let fatigue = session.perceivedFatigue {
                    HStack {
                        Text("Fatiga percibida")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        FatigueIndicator(level: fatigue)
                    }
                    .padding(12)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                // Ejercicios
                VStack(alignment: .leading, spacing: 16) {
                    Text("Ejercicios")
                        .font(.headline)

                    ForEach(exerciseGroups, id: \.exercise.id) { group in
                        ExerciseDetailCard(exercise: group.exercise, sets: group.sets)
                    }
                }

                // Notas
                if !session.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Notas")
                            .font(.headline)
                        Text(session.notes)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(14)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal)
            .padding(.top)
            .padding(.bottom, 32)
        }
        .navigationTitle(session.date.formatted(date: .abbreviated, time: .omitted))
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Subviews

private struct DetailStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon).foregroundStyle(color)
            Text(value).font(.subheadline.bold())
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct ExerciseDetailCard: View {
    let exercise: Exercise
    let sets: [ExerciseSet]

    var bestSet: ExerciseSet? {
        sets.max { Formulas.epley(weight: $0.weightKg, reps: $0.reps) < Formulas.epley(weight: $1.weightKg, reps: $1.reps) }
    }

    var totalVolume: Double { sets.reduce(0) { $0 + $1.volume } }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.name)
                        .font(.subheadline.weight(.semibold))
                    Text(exercise.primaryMuscleGroup.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let best = bestSet {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(String(format: "e1RM: %.1f kg", Formulas.epley(weight: best.weightKg, reps: best.reps)))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.blue)
                        Text(String(format: "vol: %.0f kg", totalVolume))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Tabla de sets
            VStack(spacing: 4) {
                HStack {
                    Text("Set").frame(width: 30, alignment: .leading)
                    Text("Peso").frame(maxWidth: .infinity, alignment: .center)
                    Text("Reps").frame(width: 44, alignment: .center)
                    Text("RIR").frame(width: 36, alignment: .center)
                    Text("e1RM").frame(width: 60, alignment: .trailing)
                }
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)

                ForEach(sets) { set in
                    HStack {
                        Text("\(set.setNumber)").frame(width: 30, alignment: .leading)
                        Text(set.displayWeight).frame(maxWidth: .infinity, alignment: .center)
                        Text("\(set.reps)").frame(width: 44, alignment: .center)
                        Text(set.rirActual.map { "\($0)" } ?? "—").frame(width: 36, alignment: .center)
                        Text(String(format: "%.1f", set.estimatedOneRepMax)).frame(width: 60, alignment: .trailing)
                    }
                    .font(.caption)
                    .foregroundStyle(set.isWarmup ? .secondary : .primary)
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct FatigueIndicator: View {
    let level: Int

    var color: Color {
        switch level {
        case 1...3: .green
        case 4...6: .orange
        default: .red
        }
    }

    var body: some View {
        HStack(spacing: 3) {
            ForEach(1...10, id: \.self) { i in
                Capsule()
                    .fill(i <= level ? color : Color(.tertiarySystemFill))
                    .frame(width: 14, height: 8)
            }
            Text("\(level)/10")
                .font(.caption.weight(.semibold))
                .foregroundStyle(color)
                .padding(.leading, 4)
        }
    }
}
