import Foundation
import SwiftData

@Model
final class Exercise {

    @Attribute(.unique) var id: UUID
    var wgerId: Int?                    // ID en wger.de (nil si es custom)
    var name: String
    var primaryMuscleGroup: MuscleGroup
    var secondaryMuscleGroups: [MuscleGroup]
    var equipmentRequired: Equipment
    var exerciseType: ExerciseType
    var instructions: String
    var gifURL: String?                 // URL CDN wger.de o ruta local para custom
    var thumbnailURL: String?
    var isCustom: Bool
    var ownerUserId: UUID?              // nil = ejercicio global de la biblioteca

    @Relationship(deleteRule: .nullify)
    var exerciseSlots: [ExerciseSlot] = []

    @Relationship(deleteRule: .nullify)
    var exerciseSets: [ExerciseSet] = []

    init(
        id: UUID = UUID(),
        wgerId: Int? = nil,
        name: String,
        primaryMuscleGroup: MuscleGroup,
        secondaryMuscleGroups: [MuscleGroup] = [],
        equipmentRequired: Equipment = .fullGym,
        exerciseType: ExerciseType,
        instructions: String = "",
        gifURL: String? = nil,
        thumbnailURL: String? = nil,
        isCustom: Bool = false,
        ownerUserId: UUID? = nil
    ) {
        self.id = id
        self.wgerId = wgerId
        self.name = name
        self.primaryMuscleGroup = primaryMuscleGroup
        self.secondaryMuscleGroups = secondaryMuscleGroups
        self.equipmentRequired = equipmentRequired
        self.exerciseType = exerciseType
        self.instructions = instructions
        self.gifURL = gifURL
        self.thumbnailURL = thumbnailURL
        self.isCustom = isCustom
        self.ownerUserId = ownerUserId
    }
}

// MARK: - Enums

enum MuscleGroup: String, Codable, CaseIterable, Hashable {
    case chest = "chest"
    case back = "back"
    case shoulders = "shoulders"
    case biceps = "biceps"
    case triceps = "triceps"
    case forearms = "forearms"
    case quads = "quads"
    case hamstrings = "hamstrings"
    case glutes = "glutes"
    case calves = "calves"
    case core = "core"
    case traps = "traps"

    var displayName: String {
        switch self {
        case .chest: "Pecho"
        case .back: "Espalda"
        case .shoulders: "Hombros"
        case .biceps: "Bíceps"
        case .triceps: "Tríceps"
        case .forearms: "Antebrazos"
        case .quads: "Cuádriceps"
        case .hamstrings: "Isquiotibiales"
        case .glutes: "Glúteos"
        case .calves: "Gemelos"
        case .core: "Core"
        case .traps: "Trapecios"
        }
    }

    var systemImageName: String {
        switch self {
        case .chest, .back, .shoulders, .traps: "figure.strengthtraining.traditional"
        case .biceps, .triceps, .forearms: "figure.arms.open"
        case .quads, .hamstrings, .glutes, .calves: "figure.run"
        case .core: "figure.core.training"
        }
    }

    /// Sets semanales mínimos efectivos para el grupo muscular
    var mev: Int {
        switch self {
        case .chest, .back, .quads: 10
        case .shoulders, .hamstrings, .glutes: 8
        case .biceps, .triceps: 8
        case .forearms, .calves, .core, .traps: 6
        }
    }

    /// Sets semanales máximo adaptativo
    var mav: Int {
        switch self {
        case .chest, .back, .quads: 16
        case .shoulders, .hamstrings, .glutes: 14
        case .biceps, .triceps: 14
        case .forearms, .calves, .core, .traps: 12
        }
    }

    /// Sets semanales máximo recuperable
    var mrv: Int {
        switch self {
        case .chest, .back, .quads: 22
        case .shoulders, .hamstrings, .glutes: 20
        case .biceps, .triceps: 20
        case .forearms, .calves, .core, .traps: 18
        }
    }
}

enum ExerciseType: String, Codable, CaseIterable {
    case compound = "compound"
    case isolation = "isolation"

    var displayName: String {
        switch self {
        case .compound: "Compuesto"
        case .isolation: "Aislamiento"
        }
    }
}
