import Foundation
import SwiftData

@Model
final class TrainingProgram {

    @Attribute(.unique) var id: UUID
    var name: String
    var goal: TrainingGoal
    var totalWeeks: Int
    var startDate: Date?
    var endDate: Date?
    var status: ProgramStatus
    var aiGenerated: Bool
    var aiGenerationContext: Data?      // JSON snapshot del contexto usado para generar
    var createdAt: Date

    var userProfile: UserProfile?

    @Relationship(deleteRule: .cascade)
    var mesocycles: [Mesocycle] = []

    @Relationship(deleteRule: .cascade)
    var workoutTemplates: [WorkoutTemplate] = []

    init(
        id: UUID = UUID(),
        name: String,
        goal: TrainingGoal,
        totalWeeks: Int,
        startDate: Date? = nil,
        endDate: Date? = nil,
        status: ProgramStatus = .draft,
        aiGenerated: Bool = false,
        aiGenerationContext: Data? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.goal = goal
        self.totalWeeks = totalWeeks
        self.startDate = startDate
        self.endDate = endDate
        self.status = status
        self.aiGenerated = aiGenerated
        self.aiGenerationContext = aiGenerationContext
        self.createdAt = createdAt
    }

    /// Semana actual dentro del programa (1-based), nil si el programa no está activo
    var currentWeek: Int? {
        guard status == .active, let start = startDate else { return nil }
        let daysSinceStart = Calendar.current.dateComponents([.day], from: start, to: .now).day ?? 0
        let week = (daysSinceStart / 7) + 1
        return week <= totalWeeks ? week : nil
    }
}

// MARK: - Mesocycle

@Model
final class Mesocycle {

    @Attribute(.unique) var id: UUID
    var number: Int                     // 1, 2, 3...
    var weekStart: Int                  // semana del programa donde empieza
    var weekEnd: Int
    var phase: MesocyclePhase
    var notes: String

    var program: TrainingProgram?

    init(
        id: UUID = UUID(),
        number: Int,
        weekStart: Int,
        weekEnd: Int,
        phase: MesocyclePhase,
        notes: String = ""
    ) {
        self.id = id
        self.number = number
        self.weekStart = weekStart
        self.weekEnd = weekEnd
        self.phase = phase
        self.notes = notes
    }
}

// MARK: - Enums

enum ProgramStatus: String, Codable, CaseIterable {
    case draft = "draft"
    case active = "active"
    case completed = "completed"
    case paused = "paused"

    var displayName: String {
        switch self {
        case .draft: "Borrador"
        case .active: "Activo"
        case .completed: "Completado"
        case .paused: "Pausado"
        }
    }
}

enum MesocyclePhase: String, Codable, CaseIterable {
    case accumulation = "accumulation"
    case intensification = "intensification"
    case deload = "deload"

    var displayName: String {
        switch self {
        case .accumulation: "Acumulación"
        case .intensification: "Intensificación"
        case .deload: "Descarga"
        }
    }

    var description: String {
        switch self {
        case .accumulation: "Volumen alto, intensidad moderada. Construir base de trabajo."
        case .intensification: "Volumen moderado, intensidad alta. Maximizar fuerza."
        case .deload: "Volumen bajo, recuperación activa. Supercompensación."
        }
    }
}
