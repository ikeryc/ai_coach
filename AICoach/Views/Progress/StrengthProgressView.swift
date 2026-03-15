import SwiftUI
import SwiftData
import Charts

struct StrengthProgressView: View {

    @Query(sort: \ExerciseSet.loggedAt) private var allSets: [ExerciseSet]
    @Query(sort: \Exercise.name) private var exercises: [Exercise]

    @State private var selectedExerciseId: UUID?

    private var exercisesWithData: [Exercise] {
        let idsWithSets = Set(allSets.compactMap { $0.exercise?.id })
        return exercises.filter { idsWithSets.contains($0.id) }
    }

    private var selectedExercise: Exercise? {
        guard let id = selectedExerciseId else { return nil }
        return exercises.first { $0.id == id }
    }

    private var e1RMDataPoints: [E1RMPoint] {
        guard let exercise = selectedExercise else { return [] }
        let setsForExercise = allSets.filter {
            $0.exercise?.id == exercise.id && !$0.isWarmup && $0.reps > 0 && $0.weightKg > 0
        }
        let grouped = Dictionary(grouping: setsForExercise) {
            Calendar.current.startOfDay(for: $0.loggedAt)
        }
        return grouped.map { date, sets in
            let best = sets.map { Formulas.epley(weight: $0.weightKg, reps: $0.reps) }.max() ?? 0
            return E1RMPoint(date: date, value: best)
        }
        .sorted { $0.date < $1.date }
    }

    private var bestSets: [ExerciseSet] {
        guard let exercise = selectedExercise else { return [] }
        return allSets
            .filter { $0.exercise?.id == exercise.id && !$0.isWarmup && $0.reps > 0 }
            .sorted { $0.estimatedOneRepMax > $1.estimatedOneRepMax }
            .prefix(5)
            .map { $0 }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if exercisesWithData.isEmpty {
                        emptyState
                    } else {
                        exercisePickerMenu
                        if e1RMDataPoints.isEmpty {
                            ContentUnavailableView(
                                "Sin datos",
                                systemImage: "chart.line.uptrend.xyaxis",
                                description: Text("Registra sets de este ejercicio para ver tu progreso.")
                            )
                        } else {
                            e1RMChart
                            bestSetsSection
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top)
            }
            .navigationTitle("Progreso de fuerza")
            .onAppear {
                if selectedExerciseId == nil {
                    selectedExerciseId = exercisesWithData.first?.id
                }
            }
        }
    }

    // MARK: - Exercise picker

    private var exercisePickerMenu: some View {
        Menu {
            ForEach(exercisesWithData) { exercise in
                Button(exercise.name) { selectedExerciseId = exercise.id }
            }
        } label: {
            HStack {
                Text(selectedExercise?.name ?? "Selecciona ejercicio")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - e1RM chart

    private var e1RMChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("1RM estimado")
                    .font(.headline)
                Text("Mejor set por sesión · Fórmula de Epley")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            let values = e1RMDataPoints.map(\.value)
            let maxVal = values.max() ?? 100
            let minVal = max(0, (values.min() ?? 0) - 10)

            Chart(e1RMDataPoints) { point in
                LineMark(
                    x: .value("Fecha", point.date, unit: .day),
                    y: .value("e1RM", point.value)
                )
                .foregroundStyle(Color.blue)
                .lineStyle(StrokeStyle(lineWidth: 2.5))
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("Fecha", point.date, unit: .day),
                    y: .value("e1RM", point.value)
                )
                .foregroundStyle(Color.blue)
                .symbolSize(40)
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.day().month())
                }
            }
            .chartYScale(domain: minVal...max(maxVal + 5, minVal + 10))
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    if let v = value.as(Double.self) {
                        AxisValueLabel { Text("\(Int(v)) kg") }
                    }
                }
            }
            .frame(height: 220)

            if let best = values.max() {
                HStack(spacing: 6) {
                    Image(systemName: "trophy.fill")
                        .foregroundStyle(.yellow)
                    Text("Mejor e1RM: \(String(format: "%.1f", best)) kg")
                        .font(.subheadline.weight(.semibold))
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Best sets

    private var bestSetsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Mejores sets")
                .font(.headline)

            ForEach(bestSets) { set in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(set.displayWeight) × \(set.reps) reps")
                            .font(.subheadline.weight(.semibold))
                        Text(set.loggedAt.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(String(format: "%.1f kg e1RM", set.estimatedOneRepMax))
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.12))
                        .foregroundStyle(.blue)
                        .clipShape(Capsule())
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(.bottom, 20)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Sin datos de fuerza", systemImage: "chart.line.uptrend.xyaxis")
        } description: {
            Text("Registra entrenamientos para ver tu progreso de fuerza.")
        }
        .padding(.top, 60)
    }
}

// MARK: - Data type

struct E1RMPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}
