import Foundation
import SwiftData

@Model
final class AdaptationEvent {

    @Attribute(.unique) var id: UUID
    var appliedAt: Date
    var adaptationType: AdaptationType
    var previousValue: Data?            // JSON
    var newValue: Data?                 // JSON
    var triggerReason: String
    var triggeredBy: EventTrigger
    var userApproved: Bool

    var userProfile: UserProfile?

    init(
        id: UUID = UUID(),
        appliedAt: Date = .now,
        adaptationType: AdaptationType,
        previousValue: Data? = nil,
        newValue: Data? = nil,
        triggerReason: String,
        triggeredBy: EventTrigger,
        userApproved: Bool = false
    ) {
        self.id = id
        self.appliedAt = appliedAt
        self.adaptationType = adaptationType
        self.previousValue = previousValue
        self.newValue = newValue
        self.triggerReason = triggerReason
        self.triggeredBy = triggeredBy
        self.userApproved = userApproved
    }
}

// MARK: - Enums

enum AdaptationType: String, Codable, CaseIterable {
    case caloriesUp = "calories_up"
    case caloriesDown = "calories_down"
    case volumeUp = "volume_up"
    case volumeDown = "volume_down"
    case deload = "deload"
    case programChange = "program_change"
    case macroAdjustment = "macro_adjustment"
    case weightProgression = "weight_progression"
    case weightRegression = "weight_regression"

    var displayName: String {
        switch self {
        case .caloriesUp: "Aumento de calorías"
        case .caloriesDown: "Reducción de calorías"
        case .volumeUp: "Aumento de volumen"
        case .volumeDown: "Reducción de volumen"
        case .deload: "Semana de descarga"
        case .programChange: "Cambio de programa"
        case .macroAdjustment: "Ajuste de macros"
        case .weightProgression: "Progresión de carga"
        case .weightRegression: "Reducción de carga"
        }
    }

    var systemImage: String {
        switch self {
        case .caloriesUp: "arrow.up.circle.fill"
        case .caloriesDown: "arrow.down.circle.fill"
        case .volumeUp: "plus.circle.fill"
        case .volumeDown: "minus.circle.fill"
        case .deload: "battery.25percent"
        case .programChange: "arrow.triangle.2.circlepath.circle.fill"
        case .macroAdjustment: "fork.knife.circle.fill"
        case .weightProgression: "arrow.up.right.circle.fill"
        case .weightRegression: "arrow.down.right.circle.fill"
        }
    }
}

enum EventTrigger: String, Codable {
    case ruleEngine = "rule_engine"
    case ai = "ai"
    case user = "user"

    var displayName: String {
        switch self {
        case .ruleEngine: "Automático"
        case .ai: "Entrenador IA"
        case .user: "Manual"
        }
    }
}
