import Foundation
import SwiftData

@Model
final class MealLog {

    @Attribute(.unique) var id: UUID
    var date: Date
    var mealType: MealType

    var userProfile: UserProfile?

    @Relationship(deleteRule: .cascade)
    var entries: [MealFoodEntry] = []

    init(
        id: UUID = UUID(),
        date: Date = .now,
        mealType: MealType
    ) {
        self.id = id
        self.date = date
        self.mealType = mealType
    }

    var totalCalories: Double {
        entries.reduce(0) { $0 + $1.calories }
    }

    var totalProtein: Double {
        entries.reduce(0) { $0 + $1.proteinG }
    }

    var totalCarbs: Double {
        entries.reduce(0) { $0 + $1.carbsG }
    }

    var totalFat: Double {
        entries.reduce(0) { $0 + $1.fatG }
    }
}

// MARK: - MealFoodEntry

@Model
final class MealFoodEntry {

    @Attribute(.unique) var id: UUID
    var quantityG: Double
    var calories: Double
    var proteinG: Double
    var carbsG: Double
    var fatG: Double

    var meal: MealLog?
    var foodItem: FoodItem?

    init(
        id: UUID = UUID(),
        quantityG: Double,
        foodItem: FoodItem
    ) {
        self.id = id
        self.quantityG = quantityG
        self.foodItem = foodItem
        // Macros se calculan al inicializar
        self.calories = foodItem.calories(forGrams: quantityG)
        self.proteinG = foodItem.protein(forGrams: quantityG)
        self.carbsG = foodItem.carbs(forGrams: quantityG)
        self.fatG = foodItem.fat(forGrams: quantityG)
    }

    /// Actualiza los macros calculados cuando cambia la cantidad
    func updateMacros() {
        guard let food = foodItem else { return }
        calories = food.calories(forGrams: quantityG)
        proteinG = food.protein(forGrams: quantityG)
        carbsG = food.carbs(forGrams: quantityG)
        fatG = food.fat(forGrams: quantityG)
    }
}

// MARK: - Enums

enum MealType: String, Codable, CaseIterable {
    case breakfast = "breakfast"
    case lunch = "lunch"
    case dinner = "dinner"
    case snack = "snack"
    case preWorkout = "pre_workout"
    case postWorkout = "post_workout"

    var displayName: String {
        switch self {
        case .breakfast: "Desayuno"
        case .lunch: "Almuerzo"
        case .dinner: "Cena"
        case .snack: "Snack"
        case .preWorkout: "Pre-entreno"
        case .postWorkout: "Post-entreno"
        }
    }

    var systemImage: String {
        switch self {
        case .breakfast: "sunrise.fill"
        case .lunch: "sun.max.fill"
        case .dinner: "moon.fill"
        case .snack: "apple.logo"
        case .preWorkout: "bolt.fill"
        case .postWorkout: "checkmark.seal.fill"
        }
    }

    var sortOrder: Int {
        switch self {
        case .breakfast: 0
        case .preWorkout: 1
        case .lunch: 2
        case .snack: 3
        case .postWorkout: 4
        case .dinner: 5
        }
    }
}
