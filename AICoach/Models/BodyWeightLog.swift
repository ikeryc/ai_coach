import Foundation
import SwiftData

@Model
final class BodyWeightLog {

    @Attribute(.unique) var id: UUID
    var date: Date
    var weightKg: Double
    var source: WeightSource
    var notes: String

    var userProfile: UserProfile?

    init(
        id: UUID = UUID(),
        date: Date = .now,
        weightKg: Double,
        source: WeightSource = .manual,
        notes: String = ""
    ) {
        self.id = id
        self.date = date
        self.weightKg = weightKg
        self.source = source
        self.notes = notes
    }
}

// MARK: - Enums

enum WeightSource: String, Codable, CaseIterable {
    case manual = "manual"
    case healthKit = "healthkit"

    var displayName: String {
        switch self {
        case .manual: "Manual"
        case .healthKit: "Apple Health"
        }
    }
}
