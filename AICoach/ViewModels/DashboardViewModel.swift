import Foundation
import SwiftData
import Observation

@Observable
final class DashboardViewModel {

    var isRefreshing = false

    func refresh(for profile: UserProfile, modelContext: ModelContext) {
        guard !isRefreshing else { return }
        isRefreshing = true
        WeeklyMetricsEngine.shared.computeCurrentWeek(for: profile, modelContext: modelContext)
        isRefreshing = false
    }

    func currentWeekMetrics(for profile: UserProfile) -> WeeklyMetrics? {
        let weekStart = WeeklyMetricsEngine.weekStart()
        return profile.weeklyMetrics.first {
            Calendar.current.isDate($0.weekStartDate, inSameDayAs: weekStart)
        }
    }

    func recentSessions(for profile: UserProfile, count: Int = 3) -> [TrainingSession] {
        profile.trainingSessions
            .filter { $0.completed }
            .sorted { $0.date > $1.date }
            .prefix(count)
            .map { $0 }
    }

    func activeProgram(for profile: UserProfile) -> TrainingProgram? {
        profile.trainingPrograms.first { $0.status == .active }
    }
}
