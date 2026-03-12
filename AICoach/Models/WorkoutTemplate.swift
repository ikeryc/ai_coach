import Foundation
import SwiftData

@Model
final class WorkoutTemplate {

    @Attribute(.unique) var id: UUID
    var weekNumber: Int                 // semana dentro del programa
    var dayOfWeek: Int                  // 0=lunes ... 6=domingo
    var name: String                    // "Push A", "Lower B"
    var estimatedDurationMinutes: Int
    var isDeload: Bool

    var program: TrainingProgram?

    @Relationship(deleteRule: .cascade)
    var exerciseSlots: [ExerciseSlot] = []

    @Relationship(deleteRule: .nullify)
    var sessions: [TrainingSession] = []

    init(
        id: UUID = UUID(),
        weekNumber: Int,
        dayOfWeek: Int,
        name: String,
        estimatedDurationMinutes: Int = 60,
        isDeload: Bool = false
    ) {
        self.id = id
        self.weekNumber = weekNumber
        self.dayOfWeek = dayOfWeek
        self.name = name
        self.estimatedDurationMinutes = estimatedDurationMinutes
        self.isDeload = isDeload
    }

    var dayName: String {
        let days = ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"]
        guard dayOfWeek >= 0 && dayOfWeek < days.count else { return "Día \(dayOfWeek)" }
        return days[dayOfWeek]
    }

    var sortedSlots: [ExerciseSlot] {
        exerciseSlots.sorted { $0.orderIndex < $1.orderIndex }
    }
}

// MARK: - ExerciseSlot

@Model
final class ExerciseSlot {

    @Attribute(.unique) var id: UUID
    var orderIndex: Int
    var setsCount: Int
    var repRangeMin: Int
    var repRangeMax: Int
    var rirTarget: Int                  // Reps In Reserve objetivo
    var restSeconds: Int
    var progressionModel: ProgressionModel
    var notes: String

    var workoutTemplate: WorkoutTemplate?
    var exercise: Exercise?

    init(
        id: UUID = UUID(),
        orderIndex: Int,
        setsCount: Int,
        repRangeMin: Int,
        repRangeMax: Int,
        rirTarget: Int = 2,
        restSeconds: Int = 120,
        progressionModel: ProgressionModel = .doubleProgression,
        notes: String = ""
    ) {
        self.id = id
        self.orderIndex = orderIndex
        self.setsCount = setsCount
        self.repRangeMin = repRangeMin
        self.repRangeMax = repRangeMax
        self.rirTarget = rirTarget
        self.restSeconds = restSeconds
        self.progressionModel = progressionModel
        self.notes = notes
    }

    var repRangeDisplay: String {
        "\(repRangeMin)-\(repRangeMax) reps"
    }
}

// MARK: - Enums

enum ProgressionModel: String, Codable, CaseIterable {
    case linear = "linear"
    case doubleProgression = "double_progression"
    case rirBased = "rir_based"
    case undulating = "undulating"

    var displayName: String {
        switch self {
        case .linear: "Progresión lineal"
        case .doubleProgression: "Doble progresión"
        case .rirBased: "Basada en RIR"
        case .undulating: "Ondulante"
        }
    }

    var description: String {
        switch self {
        case .linear:
            "Incrementa el peso cada sesión en una cantidad fija."
        case .doubleProgression:
            "Llega al límite superior del rango de reps antes de aumentar peso."
        case .rirBased:
            "Ajusta la carga para mantener el RIR objetivo en cada sesión."
        case .undulating:
            "Varía reps e intensidad entre sesiones de la misma semana."
        }
    }
}
