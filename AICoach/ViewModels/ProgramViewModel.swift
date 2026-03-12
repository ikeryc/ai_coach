import Foundation
import SwiftData
import Observation

@Observable
final class ProgramViewModel {

    private let syncEngine: SyncEngine

    init(syncEngine: SyncEngine = .shared) {
        self.syncEngine = syncEngine
    }

    // MARK: - Activar / Desactivar

    func activate(_ program: TrainingProgram, modelContext: ModelContext) {
        let descriptor = FetchDescriptor<TrainingProgram>(
            predicate: #Predicate { $0.status == "active" }
        )
        let active = (try? modelContext.fetch(descriptor)) ?? []
        active.forEach { $0.status = .paused }
        program.status = .active
        program.startDate = program.startDate ?? .now
        try? modelContext.save()
    }

    func pause(_ program: TrainingProgram, modelContext: ModelContext) {
        program.status = .paused
        try? modelContext.save()
    }

    func complete(_ program: TrainingProgram, modelContext: ModelContext) {
        program.status = .completed
        try? modelContext.save()
    }

    func delete(_ program: TrainingProgram, modelContext: ModelContext) {
        modelContext.delete(program)
        try? modelContext.save()
    }

    // MARK: - Crear desde template

    func createFromTemplate(_ template: ProgramTemplate, startDate: Date = .now, modelContext: ModelContext) -> TrainingProgram {
        ProgramFactory.create(from: template, startDate: startDate, modelContext: modelContext)
    }

    // MARK: - Sesión de hoy

    /// Devuelve el WorkoutTemplate que corresponde al día de hoy en el programa activo.
    func todaysWorkout(program: TrainingProgram) -> WorkoutTemplate? {
        guard let currentWeek = program.currentWeek else { return nil }
        let todayWeekday = weekdayIndex()
        return program.workoutTemplates.first {
            $0.weekNumber == currentWeek && $0.dayOfWeek == todayWeekday
        }
    }

    /// Devuelve el próximo workout no completado del programa.
    func nextWorkout(program: TrainingProgram, sessions: [TrainingSession]) -> WorkoutTemplate? {
        guard let currentWeek = program.currentWeek else { return nil }
        let completedTemplateIds = Set(sessions.compactMap { $0.workoutTemplate?.id })

        return program.workoutTemplates
            .filter {
                $0.weekNumber == currentWeek &&
                !completedTemplateIds.contains($0.id)
            }
            .sorted { $0.dayOfWeek < $1.dayOfWeek }
            .first
    }

    /// Semanas completadas en el programa (basado en sesiones realizadas).
    func completedWeeks(program: TrainingProgram, sessions: [TrainingSession]) -> Int {
        guard let start = program.startDate else { return 0 }
        let daysPassed = Calendar.current.dateComponents([.day], from: start, to: .now).day ?? 0
        return min(daysPassed / 7, program.totalWeeks)
    }

    /// Adherencia semanal: sessions completadas / sessions planificadas esta semana.
    func weeklyAdherence(program: TrainingProgram, sessions: [TrainingSession], week: Int) -> Double {
        let planned = program.workoutTemplates.filter { $0.weekNumber == week }
        guard !planned.isEmpty else { return 0 }
        let completedIds = Set(sessions.compactMap { $0.workoutTemplate?.id })
        let done = planned.filter { completedIds.contains($0.id) }.count
        return Double(done) / Double(planned.count)
    }

    // MARK: - Helpers

    /// Índice de día de la semana (0=lunes) del día actual.
    func weekdayIndex() -> Int {
        let weekday = Calendar.current.component(.weekday, from: .now)
        // Calendar: 1=domingo, 2=lunes, ...
        return (weekday + 5) % 7
    }
}
