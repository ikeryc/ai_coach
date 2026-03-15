import SwiftUI
import SwiftData
import Charts

struct VolumeChartView: View {

    @Query(
        filter: #Predicate<TrainingSession> { $0.completed },
        sort: \TrainingSession.date
    ) private var sessions: [TrainingSession]

    @State private var selectedWeeks = 4

    // MARK: - Data

    private var weeklyVolumeData: [WeekVolumeEntry] {
        let cal = Calendar.current
        var result: [WeekVolumeEntry] = []

        for weekOffset in (0..<selectedWeeks).reversed() {
            guard let weekStart = cal.date(
                byAdding: .weekOfYear, value: -weekOffset,
                to: WeeklyMetricsEngine.weekStart()
            ),
            let weekEnd = cal.date(byAdding: .day, value: 7, to: weekStart) else { continue }

            let weekSessions = sessions.filter { $0.date >= weekStart && $0.date < weekEnd }
            var volumeByMuscle: [String: Double] = [:]
            for session in weekSessions {
                for set in session.sets where !set.isWarmup {
                    guard let exercise = set.exercise else { continue }
                    volumeByMuscle[exercise.primaryMuscleGroup.displayName, default: 0] += set.volume
                }
            }
            for (muscle, volume) in volumeByMuscle {
                result.append(WeekVolumeEntry(weekStart: weekStart, muscle: muscle, volume: volume))
            }
        }
        return result
    }

    private var currentWeekMuscleStats: [(muscle: MuscleGroup, volume: Double, sets: Int)] {
        let cal = Calendar.current
        let weekStart = WeeklyMetricsEngine.weekStart()
        guard let weekEnd = cal.date(byAdding: .day, value: 7, to: weekStart) else { return [] }

        let weekSessions = sessions.filter { $0.date >= weekStart && $0.date < weekEnd }
        var volumeByMuscle: [MuscleGroup: Double] = [:]
        var setsByMuscle: [MuscleGroup: Int] = [:]

        for session in weekSessions {
            for set in session.sets where !set.isWarmup {
                guard let exercise = set.exercise else { continue }
                volumeByMuscle[exercise.primaryMuscleGroup, default: 0] += set.volume
                setsByMuscle[exercise.primaryMuscleGroup, default: 0] += 1
            }
        }

        return MuscleGroup.allCases
            .compactMap { muscle in
                guard let volume = volumeByMuscle[muscle] else { return nil }
                return (muscle: muscle, volume: volume, sets: setsByMuscle[muscle] ?? 0)
            }
            .sorted { $0.volume > $1.volume }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if sessions.isEmpty {
                        emptyState
                    } else {
                        weekPickerSection
                        if !weeklyVolumeData.isEmpty {
                            weeklyVolumeChart
                        }
                        currentWeekSetsSection
                    }
                }
                .padding(.horizontal)
                .padding(.top)
            }
            .navigationTitle("Volumen")
        }
    }

    // MARK: - Subviews

    private var weekPickerSection: some View {
        HStack {
            Text("Últimas")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Picker("Semanas", selection: $selectedWeeks) {
                Text("4 sem.").tag(4)
                Text("8 sem.").tag(8)
                Text("12 sem.").tag(12)
            }
            .pickerStyle(.segmented)
        }
    }

    private var weeklyVolumeChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Volumen semanal por músculo")
                .font(.headline)

            Chart(weeklyVolumeData) { entry in
                BarMark(
                    x: .value("Semana", entry.weekStart, unit: .weekOfYear),
                    y: .value("Volumen (kg)", entry.volume)
                )
                .foregroundStyle(by: .value("Músculo", entry.muscle))
                .cornerRadius(3)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .weekOfYear, count: 1)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.day().month())
                }
            }
            .frame(height: 250)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var currentWeekSetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Esta semana · Sets por músculo")
                .font(.headline)

            if currentWeekMuscleStats.isEmpty {
                Text("Sin sesiones esta semana")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(20)
            } else {
                ForEach(currentWeekMuscleStats, id: \.muscle) { entry in
                    MuscleVolumeRow(muscle: entry.muscle, volume: entry.volume, sets: entry.sets)
                }
            }
        }
        .padding(.bottom, 20)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Sin datos de volumen", systemImage: "chart.bar.fill")
        } description: {
            Text("Registra entrenamientos para ver el volumen por grupo muscular.")
        }
        .padding(.top, 60)
    }
}

// MARK: - Supporting types

struct WeekVolumeEntry: Identifiable {
    let id = UUID()
    let weekStart: Date
    let muscle: String
    let volume: Double
}

private struct MuscleVolumeRow: View {
    let muscle: MuscleGroup
    let volume: Double
    let sets: Int

    private var barColor: Color {
        let setsDouble = Double(sets)
        if setsDouble < Double(muscle.mev) { return .orange }
        if setsDouble <= Double(muscle.mav) { return .green }
        return .red
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(muscle.displayName)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(sets) sets · \(String(format: "%.0f", volume)) kg")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 6)
                    let progress = min(Double(sets) / Double(muscle.mrv), 1.0)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor)
                        .frame(width: geo.size.width * progress, height: 6)
                }
            }
            .frame(height: 6)

            HStack {
                Text("MEV: \(muscle.mev)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("MAV: \(muscle.mav)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("MRV: \(muscle.mrv)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
