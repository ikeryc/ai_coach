import Foundation
import SwiftData

@Model
final class TrainingSession {

    @Attribute(.unique) var id: UUID
    var date: Date
    var startedAt: Date?
    var endedAt: Date?
    var perceivedFatigue: Int?          // 1-10
    var notes: String
    var completed: Bool

    var userProfile: UserProfile?
    var workoutTemplate: WorkoutTemplate?  // nil si es sesión libre

    @Relationship(deleteRule: .cascade)
    var sets: [ExerciseSet] = []

    init(
        id: UUID = UUID(),
        date: Date = .now,
        startedAt: Date? = nil,
        endedAt: Date? = nil,
        perceivedFatigue: Int? = nil,
        notes: String = "",
        completed: Bool = false
    ) {
        self.id = id
        self.date = date
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.perceivedFatigue = perceivedFatigue
        self.notes = notes
        self.completed = completed
    }

    var duration: TimeInterval? {
        guard let start = startedAt, let end = endedAt else { return nil }
        return end.timeIntervalSince(start)
    }

    var durationDisplay: String {
        guard let d = duration else { return "--" }
        let minutes = Int(d) / 60
        let seconds = Int(d) % 60
        return minutes > 0 ? "\(minutes)m \(seconds)s" : "\(seconds)s"
    }

    var totalVolume: Double {
        sets
            .filter { !$0.isWarmup }
            .reduce(0) { $0 + ($1.weightKg * Double($1.reps)) }
    }

    var workingSets: [ExerciseSet] {
        sets.filter { !$0.isWarmup }.sorted { $0.loggedAt < $1.loggedAt }
    }
}
