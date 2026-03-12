import Foundation
import SwiftData
import Observation
import UserNotifications

// MARK: - Modelos en memoria para la sesión activa

struct ActiveExercise: Identifiable {
    let id = UUID()
    let exercise: Exercise
    var sets: [ActiveSet]

    var completedSets: [ActiveSet] { sets.filter(\.isCompleted) }
    var totalVolume: Double { completedSets.reduce(0) { $0 + ($1.weightKg * Double($1.reps)) } }
}

struct ActiveSet: Identifiable {
    let id = UUID()
    var setNumber: Int
    var weightKg: Double
    var reps: Int
    var rirActual: Int?
    var isWarmup: Bool = false
    var isCompleted: Bool = false
    /// Peso y reps de la misma posición en la sesión anterior (para referencia)
    var previousWeight: Double?
    var previousReps: Int?
}

// MARK: - ViewModel

@Observable
final class WorkoutSessionViewModel {

    // Estado de la sesión
    var activeExercises: [ActiveExercise] = []
    var sessionName: String = "Sesión libre"
    var startTime: Date = .now
    var isFinished = false
    var showSummary = false

    // Timer de descanso
    var restTimerSeconds: Int = 0
    var restTimerRunning = false
    var restTimerTarget: Int = 120

    // Estado UI
    var showExercisePicker = false
    var errorMessage: String?

    // PRs detectados al finalizar
    var detectedPRs: [PRResult] = []

    private var session: TrainingSession?
    private var restTimerTask: Task<Void, Never>?
    private var autoSaveTask: Task<Void, Never>?

    struct PRResult: Identifiable {
        let id = UUID()
        let exerciseName: String
        let newE1RM: Double
        let previousE1RM: Double?
    }

    // MARK: - Arrancar sesión

    func startSession(name: String = "Sesión libre", modelContext: ModelContext, userProfile: UserProfile?) {
        sessionName = name
        startTime = .now

        let newSession = TrainingSession(
            date: .now,
            startedAt: .now,
            completed: false
        )
        newSession.userProfile = userProfile
        modelContext.insert(newSession)
        try? modelContext.save()
        session = newSession

        startAutoSave(modelContext: modelContext)
    }

    // MARK: - Ejercicios

    func addExercise(_ exercise: Exercise, modelContext: ModelContext) {
        let previous = previousSets(for: exercise, modelContext: modelContext)
        let defaultWeight = previous.first?.weightKg ?? 20
        let defaultReps = previous.first?.reps ?? 8

        let sets = (1...3).map { i in
            ActiveSet(
                setNumber: i,
                weightKg: previous.count >= i ? previous[i-1].weightKg : defaultWeight,
                reps: previous.count >= i ? previous[i-1].reps : defaultReps,
                previousWeight: previous.count >= i ? previous[i-1].weightKg : nil,
                previousReps: previous.count >= i ? previous[i-1].reps : nil
            )
        }
        activeExercises.append(ActiveExercise(exercise: exercise, sets: sets))
    }

    func removeExercise(at offsets: IndexSet) {
        activeExercises.remove(atOffsets: offsets)
    }

    func addSet(to exerciseId: UUID) {
        guard let idx = activeExercises.firstIndex(where: { $0.id == exerciseId }) else { return }
        let current = activeExercises[idx].sets
        let newNumber = (current.map(\.setNumber).max() ?? 0) + 1
        let lastSet = current.last
        activeExercises[idx].sets.append(ActiveSet(
            setNumber: newNumber,
            weightKg: lastSet?.weightKg ?? 20,
            reps: lastSet?.reps ?? 8
        ))
    }

    func removeSet(exerciseId: UUID, setId: UUID) {
        guard let eIdx = activeExercises.firstIndex(where: { $0.id == exerciseId }) else { return }
        activeExercises[eIdx].sets.removeAll { $0.id == setId }
        // Renumerar
        for (i, _) in activeExercises[eIdx].sets.enumerated() {
            activeExercises[eIdx].sets[i].setNumber = i + 1
        }
    }

    // MARK: - Completar un set

    func completeSet(exerciseId: UUID, setId: UUID, modelContext: ModelContext) {
        guard let eIdx = activeExercises.firstIndex(where: { $0.id == exerciseId }),
              let sIdx = activeExercises[eIdx].sets.firstIndex(where: { $0.id == setId }),
              let session
        else { return }

        activeExercises[eIdx].sets[sIdx].isCompleted = true
        let activeSet = activeExercises[eIdx].sets[sIdx]
        let exercise = activeExercises[eIdx].exercise

        // Persistir en SwiftData inmediatamente
        let exerciseSet = ExerciseSet(
            setNumber: activeSet.setNumber,
            weightKg: activeSet.weightKg,
            reps: activeSet.reps,
            rirActual: activeSet.rirActual,
            isWarmup: activeSet.isWarmup
        )
        exerciseSet.session = session
        exerciseSet.exercise = exercise
        modelContext.insert(exerciseSet)
        try? modelContext.save()

        // Arrancar timer de descanso
        startRestTimer(seconds: restTimerTarget)
    }

    // MARK: - Finalizar sesión

    func finishSession(modelContext: ModelContext) {
        guard let session else { return }
        session.endedAt = .now
        session.completed = true
        try? modelContext.save()

        detectedPRs = detectPRs(modelContext: modelContext)
        stopAutoSave()
        stopRestTimer()
        showSummary = true
    }

    func discardSession(modelContext: ModelContext) {
        if let session {
            modelContext.delete(session)
            try? modelContext.save()
        }
        stopAutoSave()
        stopRestTimer()
        isFinished = true
    }

    // MARK: - Duración

    var elapsedSeconds: Int {
        Int(Date.now.timeIntervalSince(startTime))
    }

    var elapsedDisplay: String {
        let h = elapsedSeconds / 3600
        let m = (elapsedSeconds % 3600) / 60
        let s = elapsedSeconds % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%02d:%02d", m, s)
    }

    // MARK: - Volumen total

    var totalVolume: Double {
        activeExercises.reduce(0) { $0 + $1.totalVolume }
    }

    var totalCompletedSets: Int {
        activeExercises.reduce(0) { $0 + $1.completedSets.count }
    }

    // MARK: - Rest Timer

    func startRestTimer(seconds: Int) {
        stopRestTimer()
        restTimerSeconds = seconds
        restTimerRunning = true

        restTimerTask = Task { @MainActor in
            while restTimerSeconds > 0 && !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                restTimerSeconds -= 1
            }
            if restTimerSeconds == 0 {
                restTimerRunning = false
                scheduleRestNotification()
            }
        }
    }

    func stopRestTimer() {
        restTimerTask?.cancel()
        restTimerTask = nil
        restTimerRunning = false
        restTimerSeconds = 0
    }

    private func scheduleRestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Descanso completado"
        content.body = "Listo para el siguiente set 💪"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "rest_timer_\(UUID())",
            content: content,
            trigger: nil // inmediato
        )
        UNUserNotificationCenter.current().add(request)
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    // MARK: - Auto-save

    private func startAutoSave(modelContext: ModelContext) {
        autoSaveTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Constants.Training.autoSaveInterval))
                try? modelContext.save()
            }
        }
    }

    private func stopAutoSave() {
        autoSaveTask?.cancel()
        autoSaveTask = nil
    }

    // MARK: - Historial

    private func previousSets(for exercise: Exercise, modelContext: ModelContext) -> [ExerciseSet] {
        let exerciseId = exercise.id
        let descriptor = FetchDescriptor<ExerciseSet>(
            predicate: #Predicate { $0.exercise?.id == exerciseId && !$0.isWarmup },
            sortBy: [SortDescriptor(\.loggedAt, order: .reverse)]
        )
        let allSets = (try? modelContext.fetch(descriptor)) ?? []
        // Encontrar la sesión más reciente y devolver sus sets
        guard let lastSessionId = allSets.first?.session?.id else { return [] }
        return allSets
            .filter { $0.session?.id == lastSessionId }
            .sorted { $0.setNumber < $1.setNumber }
    }

    // MARK: - Detección de PRs

    private func detectPRs(modelContext: ModelContext) -> [PRResult] {
        var results: [PRResult] = []

        for activeEx in activeExercises {
            let bestCurrentE1RM = activeEx.completedSets
                .filter { !$0.isWarmup }
                .map { Formulas.epley(weight: $0.weightKg, reps: $0.reps) }
                .max() ?? 0

            guard bestCurrentE1RM > 0 else { continue }

            // Buscar el mejor e1RM histórico (excluyendo la sesión actual)
            let exerciseId = activeEx.exercise.id
            let currentSessionId = session?.id
            let descriptor = FetchDescriptor<ExerciseSet>(
                predicate: #Predicate {
                    $0.exercise?.id == exerciseId &&
                    !$0.isWarmup &&
                    $0.session?.id != currentSessionId
                }
            )
            let historicalSets = (try? modelContext.fetch(descriptor)) ?? []
            let bestHistorical = historicalSets
                .map { Formulas.epley(weight: $0.weightKg, reps: $0.reps) }
                .max()

            if bestHistorical == nil || bestCurrentE1RM > (bestHistorical! * 1.005) {
                results.append(PRResult(
                    exerciseName: activeEx.exercise.name,
                    newE1RM: bestCurrentE1RM,
                    previousE1RM: bestHistorical
                ))
            }
        }
        return results
    }
}
