import SwiftUI
import SwiftData

struct ActiveProgramView: View {

    let program: TrainingProgram
    let onStartWorkout: (WorkoutTemplate?) -> Void

    @Query private var sessions: [TrainingSession]
    @State private var viewModel = ProgramViewModel()
    @State private var selectedWeek: Int = 1

    private var currentWeek: Int { program.currentWeek ?? 1 }

    private var sessionsThisProgram: [TrainingSession] {
        guard let start = program.startDate else { return [] }
        return sessions.filter { $0.date >= start }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            programHeader
            weekSelector
            weekGrid
            todayCard
        }
    }

    // MARK: - Header del programa

    private var programHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(program.name)
                        .font(.title3.bold())
                    Text("\(program.goal.displayName) · \(program.totalWeeks) semanas")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                // Anillo de adherencia semanal
                AdherenceRing(
                    value: viewModel.weeklyAdherence(
                        program: program,
                        sessions: sessionsThisProgram,
                        week: currentWeek
                    )
                )
            }

            // Barra de progreso del programa completo
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Semana \(currentWeek) de \(program.totalWeeks)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int((Double(currentWeek) / Double(program.totalWeeks)) * 100))%")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.blue)
                }
                ProgressView(value: Double(currentWeek), total: Double(program.totalWeeks))
                    .tint(.blue)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Selector de semana

    private var weekSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(1...program.totalWeeks, id: \.self) { week in
                    let adherence = viewModel.weeklyAdherence(
                        program: program,
                        sessions: sessionsThisProgram,
                        week: week
                    )
                    let isCurrent = week == currentWeek
                    let isDeload = program.workoutTemplates.first { $0.weekNumber == week }?.isDeload == true

                    Button {
                        selectedWeek = week
                    } label: {
                        VStack(spacing: 3) {
                            Text("S\(week)")
                                .font(.caption.weight(isCurrent ? .bold : .regular))
                            if isDeload {
                                Image(systemName: "battery.25percent")
                                    .font(.caption2)
                                    .foregroundStyle(.orange)
                            } else if adherence >= 1.0 {
                                Image(systemName: "checkmark")
                                    .font(.caption2)
                                    .foregroundStyle(.green)
                            } else if adherence > 0 {
                                Image(systemName: "circle.lefthalf.filled")
                                    .font(.caption2)
                                    .foregroundStyle(.blue)
                            } else {
                                Image(systemName: "circle")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .frame(width: 42, height: 48)
                        .background(
                            selectedWeek == week ? Color.blue : (isCurrent ? Color.blue.opacity(0.1) : Color(.tertiarySystemFill))
                        )
                        .foregroundStyle(selectedWeek == week ? .white : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            isCurrent && selectedWeek != week ?
                            RoundedRectangle(cornerRadius: 10).stroke(Color.blue, lineWidth: 1.5) : nil
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Grid de la semana seleccionada

    private var weekGrid: some View {
        let days = program.workoutTemplates
            .filter { $0.weekNumber == selectedWeek }
            .sorted { $0.dayOfWeek < $1.dayOfWeek }

        let completedIds = Set(sessionsThisProgram.compactMap { $0.workoutTemplate?.id })

        return VStack(spacing: 8) {
            ForEach(days) { day in
                let isCompleted = completedIds.contains(day.id)
                WorkoutDayRow(
                    template: day,
                    isCompleted: isCompleted,
                    isToday: day.dayOfWeek == viewModel.weekdayIndex() && selectedWeek == currentWeek,
                    onTap: { onStartWorkout(day) }
                )
            }

            if days.isEmpty {
                Text("No hay sesiones planificadas esta semana")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
    }

    // MARK: - Card de hoy

    @ViewBuilder
    private var todayCard: some View {
        if let today = viewModel.todaysWorkout(program: program) {
            let completedIds = Set(sessionsThisProgram.compactMap { $0.workoutTemplate?.id })
            let isDone = completedIds.contains(today.id)

            if !isDone {
                Button {
                    onStartWorkout(today)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Hoy: \(today.name)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                            Text("\(today.sortedSlots.count) ejercicios · ~\(today.estimatedDurationMinutes) min")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        Spacer()
                        Image(systemName: "play.fill")
                            .font(.title3)
                            .foregroundStyle(.white)
                    }
                    .padding(16)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - WorkoutDayRow

private struct WorkoutDayRow: View {
    let template: WorkoutTemplate
    let isCompleted: Bool
    let isToday: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Día de la semana
                VStack(spacing: 2) {
                    Text(String(template.dayName.prefix(3)))
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(isToday ? .blue : .secondary)
                }
                .frame(width: 36)

                // Contenido
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(template.name)
                            .font(.subheadline.weight(.semibold))
                        if template.isDeload {
                            Text("Descarga")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.15))
                                .foregroundStyle(.orange)
                                .clipShape(Capsule())
                        }
                    }

                    let exerciseNames = template.sortedSlots
                        .compactMap { $0.exercise?.name }
                        .prefix(3)
                        .joined(separator: " · ")

                    if !exerciseNames.isEmpty {
                        Text(exerciseNames)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Estado
                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else if isToday {
                    Image(systemName: "play.circle.fill")
                        .foregroundStyle(.blue)
                        .font(.title3)
                } else {
                    Image(systemName: "circle")
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(12)
            .background(
                isToday && !isCompleted
                    ? Color.blue.opacity(0.06)
                    : Color(.secondarySystemGroupedBackground)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                isToday && !isCompleted
                    ? RoundedRectangle(cornerRadius: 12).stroke(Color.blue.opacity(0.3), lineWidth: 1) : nil
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - AdherenceRing

struct AdherenceRing: View {
    let value: Double // 0.0 - 1.0

    var color: Color { value >= 1 ? .green : value >= 0.5 ? .blue : .orange }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.tertiarySystemFill), lineWidth: 5)
            Circle()
                .trim(from: 0, to: min(value, 1.0))
                .stroke(color, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: value)
            Text("\(Int(value * 100))%")
                .font(.caption2.bold())
                .foregroundStyle(color)
        }
        .frame(width: 48, height: 48)
    }
}
