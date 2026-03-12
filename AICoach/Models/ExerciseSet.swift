import Foundation
import SwiftData

@Model
final class ExerciseSet {

    @Attribute(.unique) var id: UUID
    var setNumber: Int
    var weightKg: Double
    var reps: Int
    var rirActual: Int?                 // RIR real reportado (nil si no se registró)
    var isWarmup: Bool
    var loggedAt: Date

    var session: TrainingSession?
    var exercise: Exercise?

    init(
        id: UUID = UUID(),
        setNumber: Int,
        weightKg: Double,
        reps: Int,
        rirActual: Int? = nil,
        isWarmup: Bool = false,
        loggedAt: Date = .now
    ) {
        self.id = id
        self.setNumber = setNumber
        self.weightKg = weightKg
        self.reps = reps
        self.rirActual = rirActual
        self.isWarmup = isWarmup
        self.loggedAt = loggedAt
    }

    /// e1RM estimado usando fórmula de Epley
    var estimatedOneRepMax: Double {
        Formulas.epley(weight: weightKg, reps: reps)
    }

    /// Volumen del set (kg × reps)
    var volume: Double {
        weightKg * Double(reps)
    }

    var displayWeight: String {
        weightKg.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(weightKg)) kg"
            : "\(weightKg) kg"
    }
}
