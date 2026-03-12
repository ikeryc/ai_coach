import Foundation
import SwiftData

@Model
final class NutritionLog {

    @Attribute(.unique) var id: UUID
    var date: Date
    var calories: Int
    var proteinG: Double
    var carbsG: Double
    var fatG: Double
    var adherencePercentage: Double?    // calories_consumed / calories_target × 100
    var notes: String

    var userProfile: UserProfile?

    init(
        id: UUID = UUID(),
        date: Date = .now,
        calories: Int = 0,
        proteinG: Double = 0,
        carbsG: Double = 0,
        fatG: Double = 0,
        adherencePercentage: Double? = nil,
        notes: String = ""
    ) {
        self.id = id
        self.date = date
        self.calories = calories
        self.proteinG = proteinG
        self.carbsG = carbsG
        self.fatG = fatG
        self.adherencePercentage = adherencePercentage
        self.notes = notes
    }
}
