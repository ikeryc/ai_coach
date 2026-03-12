import Foundation
import SwiftData

@Model
final class UserProfile {

    @Attribute(.unique) var id: UUID
    var supabaseUserId: String
    var age: Int
    var sex: Sex
    var weightKg: Double
    var heightCm: Double
    var bodyFatPercentage: Double?
    var experienceLevel: ExperienceLevel
    var primaryGoal: TrainingGoal
    var availableTrainingDays: Int
    var equipment: Equipment
    var updatedAt: Date

    @Relationship(deleteRule: .cascade)
    var trainingPrograms: [TrainingProgram] = []

    @Relationship(deleteRule: .cascade)
    var trainingSessions: [TrainingSession] = []

    @Relationship(deleteRule: .cascade)
    var bodyWeightLogs: [BodyWeightLog] = []

    @Relationship(deleteRule: .cascade)
    var nutritionGoals: [NutritionGoal] = []

    @Relationship(deleteRule: .cascade)
    var nutritionLogs: [NutritionLog] = []

    @Relationship(deleteRule: .cascade)
    var weeklyMetrics: [WeeklyMetrics] = []

    @Relationship(deleteRule: .cascade)
    var adaptationEvents: [AdaptationEvent] = []

    @Relationship(deleteRule: .cascade)
    var aiConversations: [AIConversation] = []

    init(
        id: UUID = UUID(),
        supabaseUserId: String = "",
        age: Int,
        sex: Sex,
        weightKg: Double,
        heightCm: Double,
        bodyFatPercentage: Double? = nil,
        experienceLevel: ExperienceLevel,
        primaryGoal: TrainingGoal,
        availableTrainingDays: Int,
        equipment: Equipment,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.supabaseUserId = supabaseUserId
        self.age = age
        self.sex = sex
        self.weightKg = weightKg
        self.heightCm = heightCm
        self.bodyFatPercentage = bodyFatPercentage
        self.experienceLevel = experienceLevel
        self.primaryGoal = primaryGoal
        self.availableTrainingDays = availableTrainingDays
        self.equipment = equipment
        self.updatedAt = updatedAt
    }
}

// MARK: - Enums

enum Sex: String, Codable, CaseIterable {
    case male = "male"
    case female = "female"
    case other = "other"

    var displayName: String {
        switch self {
        case .male: "Hombre"
        case .female: "Mujer"
        case .other: "Otro"
        }
    }
}

enum ExperienceLevel: String, Codable, CaseIterable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"

    var displayName: String {
        switch self {
        case .beginner: "Principiante"
        case .intermediate: "Intermedio"
        case .advanced: "Avanzado"
        }
    }

    var description: String {
        switch self {
        case .beginner: "Menos de 1 año entrenando"
        case .intermediate: "1-3 años entrenando"
        case .advanced: "Más de 3 años entrenando"
        }
    }
}

enum TrainingGoal: String, Codable, CaseIterable {
    case hypertrophy = "hypertrophy"
    case strength = "strength"
    case fatLoss = "fat_loss"
    case recomposition = "recomposition"

    var displayName: String {
        switch self {
        case .hypertrophy: "Ganar músculo"
        case .strength: "Ganar fuerza"
        case .fatLoss: "Perder grasa"
        case .recomposition: "Recomposición"
        }
    }

    var description: String {
        switch self {
        case .hypertrophy: "Maximizar masa muscular con superávit calórico"
        case .strength: "Incrementar fuerza en movimientos principales"
        case .fatLoss: "Reducir grasa preservando músculo"
        case .recomposition: "Ganar músculo y perder grasa simultáneamente"
        }
    }

    /// Rango de cambio de peso semanal objetivo como % del peso corporal
    var weeklyWeightChangeRange: ClosedRange<Double> {
        switch self {
        case .hypertrophy: 0.0025...0.005
        case .strength: 0.001...0.003
        case .fatLoss: -0.01 ... -0.005
        case .recomposition: -0.001...0.001
        }
    }
}

enum Equipment: String, Codable, CaseIterable {
    case fullGym = "full_gym"
    case home = "home"
    case dumbbellsOnly = "dumbbells_only"

    var displayName: String {
        switch self {
        case .fullGym: "Gimnasio completo"
        case .home: "Casa (sin equipamiento)"
        case .dumbbellsOnly: "Mancuernas únicamente"
        }
    }
}
