import Foundation
import SwiftData

@Model
final class WeeklyMetrics {

    @Attribute(.unique) var id: UUID
    var weekStartDate: Date
    var avgWeight7d: Double?
    var weightChangeVsPrevWeek: Double?
    /// Estimaciones de 1RM por ejercicio: [exerciseId: 1rm_kg]
    var estimated1RM: Data?
    /// Volumen total por grupo muscular: [muscleGroup: volume_kg]
    var totalVolumeByMuscle: Data?
    var avgCalorieAdherence: Double?
    var trainingSessionsCompleted: Int
    var trainingSessionsPlanned: Int
    var computedAt: Date

    var userProfile: UserProfile?

    init(
        id: UUID = UUID(),
        weekStartDate: Date,
        avgWeight7d: Double? = nil,
        weightChangeVsPrevWeek: Double? = nil,
        estimated1RM: Data? = nil,
        totalVolumeByMuscle: Data? = nil,
        avgCalorieAdherence: Double? = nil,
        trainingSessionsCompleted: Int = 0,
        trainingSessionsPlanned: Int = 0,
        computedAt: Date = .now
    ) {
        self.id = id
        self.weekStartDate = weekStartDate
        self.avgWeight7d = avgWeight7d
        self.weightChangeVsPrevWeek = weightChangeVsPrevWeek
        self.estimated1RM = estimated1RM
        self.totalVolumeByMuscle = totalVolumeByMuscle
        self.avgCalorieAdherence = avgCalorieAdherence
        self.trainingSessionsCompleted = trainingSessionsCompleted
        self.trainingSessionsPlanned = trainingSessionsPlanned
        self.computedAt = computedAt
    }

    var adherenceRatio: Double {
        guard trainingSessionsPlanned > 0 else { return 0 }
        return Double(trainingSessionsCompleted) / Double(trainingSessionsPlanned)
    }

    var adherencePercentage: Int {
        Int(adherenceRatio * 100)
    }

    /// Deserializa el diccionario de 1RMs
    func decoded1RM() -> [String: Double]? {
        guard let data = estimated1RM else { return nil }
        return try? JSONDecoder().decode([String: Double].self, from: data)
    }

    /// Deserializa el volumen por grupo muscular
    func decodedVolumeByMuscle() -> [String: Double]? {
        guard let data = totalVolumeByMuscle else { return nil }
        return try? JSONDecoder().decode([String: Double].self, from: data)
    }
}
