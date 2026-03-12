import Foundation
import SwiftData

@Model
final class NutritionGoal {

    @Attribute(.unique) var id: UUID
    var startDate: Date
    var endDate: Date?                  // nil = vigente
    var caloriesTarget: Int
    var proteinG: Int
    var carbsG: Int
    var fatG: Int
    var adjustmentReason: String?
    var createdBy: GoalCreator

    var userProfile: UserProfile?

    init(
        id: UUID = UUID(),
        startDate: Date = .now,
        endDate: Date? = nil,
        caloriesTarget: Int,
        proteinG: Int,
        carbsG: Int,
        fatG: Int,
        adjustmentReason: String? = nil,
        createdBy: GoalCreator = .user
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.caloriesTarget = caloriesTarget
        self.proteinG = proteinG
        self.carbsG = carbsG
        self.fatG = fatG
        self.adjustmentReason = adjustmentReason
        self.createdBy = createdBy
    }

    var isActive: Bool {
        endDate == nil
    }

    /// Crea un objetivo nutricional calculando macros automáticamente
    static func calculate(
        weightKg: Double,
        heightCm: Double,
        age: Int,
        sex: Sex,
        goal: TrainingGoal,
        activityLevel: ActivityLevel = .moderatelyActive
    ) -> (calories: Int, proteinG: Int, carbsG: Int, fatG: Int) {
        let tdee = Formulas.tdee(
            weightKg: weightKg,
            heightCm: heightCm,
            age: age,
            sex: sex,
            activityLevel: activityLevel
        )

        let targetCalories: Double
        switch goal {
        case .hypertrophy:
            targetCalories = tdee + 300
        case .strength:
            targetCalories = tdee + 200
        case .fatLoss:
            targetCalories = tdee - 400
        case .recomposition:
            targetCalories = tdee
        }

        let proteinMultiplier: Double = goal == .fatLoss || goal == .recomposition ? 2.2 : 2.0
        let proteinG = Int(weightKg * proteinMultiplier)
        let proteinCalories = proteinG * 4

        let fatCalories = targetCalories * 0.25
        let fatG = Int(fatCalories / 9)

        let carbCalories = targetCalories - Double(proteinCalories) - fatCalories
        let carbsG = Int(max(0, carbCalories / 4))

        return (Int(targetCalories), proteinG, carbsG, fatG)
    }
}

// MARK: - Enums

enum GoalCreator: String, Codable {
    case ai = "ai"
    case user = "user"
    case ruleEngine = "rule_engine"

    var displayName: String {
        switch self {
        case .ai: "Entrenador IA"
        case .user: "Manual"
        case .ruleEngine: "Ajuste automático"
        }
    }
}

enum ActivityLevel: String, Codable, CaseIterable {
    case sedentary = "sedentary"
    case lightlyActive = "lightly_active"
    case moderatelyActive = "moderately_active"
    case veryActive = "very_active"
    case extraActive = "extra_active"

    var displayName: String {
        switch self {
        case .sedentary: "Sedentario (sin ejercicio)"
        case .lightlyActive: "Ligero (1-3 días/semana)"
        case .moderatelyActive: "Moderado (3-5 días/semana)"
        case .veryActive: "Activo (6-7 días/semana)"
        case .extraActive: "Muy activo (trabajo físico + ejercicio)"
        }
    }

    var multiplier: Double {
        switch self {
        case .sedentary: 1.2
        case .lightlyActive: 1.375
        case .moderatelyActive: 1.55
        case .veryActive: 1.725
        case .extraActive: 1.9
        }
    }
}
