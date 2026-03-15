import Foundation
import SwiftData
import Observation

/// Computes and persists WeeklyMetrics from raw training, weight, and nutrition data.
@Observable
final class WeeklyMetricsEngine {

    static let shared = WeeklyMetricsEngine()

    var isComputing = false

    /// Computes metrics for the current calendar week and saves them.
    func computeCurrentWeek(for profile: UserProfile, modelContext: ModelContext) {
        compute(weekStart: Self.weekStart(for: .now), for: profile, modelContext: modelContext)
    }

    func compute(weekStart: Date, for profile: UserProfile, modelContext: ModelContext) {
        isComputing = true
        defer { isComputing = false }

        let cal = Calendar.current
        guard let weekEnd = cal.date(byAdding: .day, value: 7, to: weekStart),
              let prevWeekStart = cal.date(byAdding: .day, value: -7, to: weekStart) else { return }

        // --- Sessions ---
        let weekSessions = profile.trainingSessions.filter {
            $0.completed && $0.date >= weekStart && $0.date < weekEnd
        }

        // --- Weight ---
        let thisWeekWeights = profile.bodyWeightLogs
            .filter { $0.date >= weekStart && $0.date < weekEnd }
            .map(\.weightKg)
        let prevWeekWeights = profile.bodyWeightLogs
            .filter { $0.date >= prevWeekStart && $0.date < weekStart }
            .map(\.weightKg)

        let avgWeight: Double? = thisWeekWeights.isEmpty ? nil :
            thisWeekWeights.reduce(0, +) / Double(thisWeekWeights.count)
        let prevAvgWeight: Double? = prevWeekWeights.isEmpty ? nil :
            prevWeekWeights.reduce(0, +) / Double(prevWeekWeights.count)
        let weightChange: Double? = avgWeight.flatMap { aw in prevAvgWeight.map { aw - $0 } }

        // --- e1RM per exercise (best set this week) ---
        var oneRMs: [String: Double] = [:]
        for session in weekSessions {
            for set in session.sets where !set.isWarmup && set.reps > 0 && set.weightKg > 0 {
                guard let exercise = set.exercise else { continue }
                let key = exercise.id.uuidString
                let e1rm = Formulas.epley(weight: set.weightKg, reps: set.reps)
                oneRMs[key] = max(oneRMs[key] ?? 0, e1rm)
            }
        }
        let oneRMData = try? JSONEncoder().encode(oneRMs)

        // --- Volume by muscle group ---
        var volumeByMuscle: [String: Double] = [:]
        for session in weekSessions {
            for set in session.sets where !set.isWarmup {
                guard let exercise = set.exercise else { continue }
                volumeByMuscle[exercise.primaryMuscleGroup.rawValue, default: 0] += set.volume
            }
        }
        let volumeData = try? JSONEncoder().encode(volumeByMuscle)

        // --- Calorie adherence ---
        let adherenceValues = profile.nutritionLogs
            .filter { $0.date >= weekStart && $0.date < weekEnd }
            .compactMap(\.adherencePercentage)
        let avgCalAdherence: Double? = adherenceValues.isEmpty ? nil :
            adherenceValues.reduce(0, +) / Double(adherenceValues.count)

        // --- Planned sessions from active program ---
        var plannedCount = weekSessions.count
        if let prog = profile.trainingPrograms.first(where: { $0.status == .active }),
           let weekNum = prog.currentWeek {
            let templatesThisWeek = prog.workoutTemplates.filter {
                $0.weekNumber == weekNum && !$0.isDeload
            }
            if !templatesThisWeek.isEmpty {
                plannedCount = max(plannedCount, templatesThisWeek.count)
            }
        }

        // --- Save or update ---
        if let existing = profile.weeklyMetrics.first(where: {
            cal.isDate($0.weekStartDate, inSameDayAs: weekStart)
        }) {
            existing.avgWeight7d = avgWeight
            existing.weightChangeVsPrevWeek = weightChange
            existing.estimated1RM = oneRMData
            existing.totalVolumeByMuscle = volumeData
            existing.avgCalorieAdherence = avgCalAdherence
            existing.trainingSessionsCompleted = weekSessions.count
            existing.trainingSessionsPlanned = plannedCount
            existing.computedAt = .now
        } else {
            let metrics = WeeklyMetrics(
                weekStartDate: weekStart,
                avgWeight7d: avgWeight,
                weightChangeVsPrevWeek: weightChange,
                estimated1RM: oneRMData,
                totalVolumeByMuscle: volumeData,
                avgCalorieAdherence: avgCalAdherence,
                trainingSessionsCompleted: weekSessions.count,
                trainingSessionsPlanned: plannedCount
            )
            metrics.userProfile = profile
            modelContext.insert(metrics)
        }
        try? modelContext.save()
    }

    /// Returns the Monday of the week containing the given date.
    static func weekStart(for date: Date = .now) -> Date {
        var cal = Calendar.current
        cal.firstWeekday = 2 // Monday
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return cal.date(from: comps) ?? date
    }
}
