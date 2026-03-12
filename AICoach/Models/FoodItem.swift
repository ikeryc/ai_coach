import Foundation
import SwiftData

@Model
final class FoodItem {

    @Attribute(.unique) var id: UUID
    var externalId: String?             // ID en Open Food Facts o USDA
    var source: FoodSource
    var name: String
    var brand: String?
    var barcode: String?
    var caloriesPer100g: Double
    var proteinPer100g: Double
    var carbsPer100g: Double
    var fatPer100g: Double
    var fiberPer100g: Double
    var servingSizeG: Double?           // Porción habitual en gramos
    var ownerUserId: UUID?              // nil = alimento global/cacheado

    @Relationship(deleteRule: .nullify)
    var mealEntries: [MealFoodEntry] = []

    init(
        id: UUID = UUID(),
        externalId: String? = nil,
        source: FoodSource = .custom,
        name: String,
        brand: String? = nil,
        barcode: String? = nil,
        caloriesPer100g: Double,
        proteinPer100g: Double,
        carbsPer100g: Double,
        fatPer100g: Double,
        fiberPer100g: Double = 0,
        servingSizeG: Double? = nil,
        ownerUserId: UUID? = nil
    ) {
        self.id = id
        self.externalId = externalId
        self.source = source
        self.name = name
        self.brand = brand
        self.barcode = barcode
        self.caloriesPer100g = caloriesPer100g
        self.proteinPer100g = proteinPer100g
        self.carbsPer100g = carbsPer100g
        self.fatPer100g = fatPer100g
        self.fiberPer100g = fiberPer100g
        self.servingSizeG = servingSizeG
        self.ownerUserId = ownerUserId
    }

    func calories(forGrams grams: Double) -> Double {
        (grams / 100.0) * caloriesPer100g
    }

    func protein(forGrams grams: Double) -> Double {
        (grams / 100.0) * proteinPer100g
    }

    func carbs(forGrams grams: Double) -> Double {
        (grams / 100.0) * carbsPer100g
    }

    func fat(forGrams grams: Double) -> Double {
        (grams / 100.0) * fatPer100g
    }
}

// MARK: - Enums

enum FoodSource: String, Codable, CaseIterable {
    case openFoodFacts = "open_food_facts"
    case usda = "usda"
    case custom = "custom"

    var displayName: String {
        switch self {
        case .openFoodFacts: "Open Food Facts"
        case .usda: "USDA"
        case .custom: "Personal"
        }
    }
}
