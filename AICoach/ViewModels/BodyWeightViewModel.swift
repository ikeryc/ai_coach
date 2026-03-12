import Foundation
import SwiftData
import Observation

@Observable
final class BodyWeightViewModel {

    private let healthKit: HealthKitService
    private let syncEngine: SyncEngine

    var isLoadingHealthKit = false
    var errorMessage: String?

    init(
        healthKit: HealthKitService = .shared,
        syncEngine: SyncEngine = .shared
    ) {
        self.healthKit = healthKit
        self.syncEngine = syncEngine
    }

    // MARK: - HealthKit sync

    func syncFromHealthKit(modelContext: ModelContext, userProfile: UserProfile?) async {
        guard await healthKit.requestAuthorization() else { return }
        isLoadingHealthKit = true

        let history = await healthKit.fetchWeightHistory(days: Constants.HealthKit.initialSyncDays)

        for entry in history {
            // Evitar duplicados: comprueba si ya existe entrada en esa fecha
            let dayStart = Calendar.current.startOfDay(for: entry.date)
            let descriptor = FetchDescriptor<BodyWeightLog>(
                predicate: #Predicate { $0.date >= dayStart }
            )
            let existing = (try? modelContext.fetch(descriptor)) ?? []
            guard existing.isEmpty else { continue }

            let log = BodyWeightLog(
                date: entry.date,
                weightKg: entry.weightKg,
                source: .healthKit
            )
            log.userProfile = userProfile
            modelContext.insert(log)
        }

        try? modelContext.save()
        isLoadingHealthKit = false
    }

    // MARK: - Añadir entrada manual

    func addWeightEntry(
        weightKg: Double,
        date: Date,
        notes: String,
        modelContext: ModelContext,
        userProfile: UserProfile?
    ) async {
        let log = BodyWeightLog(
            date: date,
            weightKg: weightKg,
            source: .manual,
            notes: notes
        )
        log.userProfile = userProfile
        modelContext.insert(log)

        do {
            try modelContext.save()
        } catch {
            errorMessage = error.localizedDescription
            return
        }

        // Escribir en HealthKit si tenemos permiso
        _ = await healthKit.saveWeight(weightKg, date: date)

        // Sync a Supabase
        await syncEngine.syncWeightLog(log)
    }

    func deleteEntry(_ log: BodyWeightLog, modelContext: ModelContext) {
        modelContext.delete(log)
        try? modelContext.save()
    }

    // MARK: - Cálculos para gráfico

    struct ChartPoint: Identifiable {
        let id = UUID()
        let date: Date
        let weight: Double
    }

    /// Calcula la media móvil de 7 días para el gráfico.
    func movingAverage(from logs: [BodyWeightLog]) -> [ChartPoint] {
        let sorted = logs.sorted { $0.date < $1.date }
        let weights = sorted.map { $0.weightKg }
        let averages = Formulas.movingAverage(values: weights, window: Constants.UI.weightMovingAverageWindow)

        return zip(sorted, averages).compactMap { log, avg in
            guard let avg else { return nil }
            return ChartPoint(date: log.date, weight: avg)
        }
    }

    /// Cambio total de peso desde el primer registro.
    func totalChange(from logs: [BodyWeightLog]) -> Double? {
        let sorted = logs.sorted { $0.date < $1.date }
        guard let first = sorted.first, let last = sorted.last, first.id != last.id else { return nil }
        return last.weightKg - first.weightKg
    }

    /// Cambio en los últimos 7 días.
    func weeklyChange(from logs: [BodyWeightLog]) -> Double? {
        let sorted = logs.sorted { $0.date < $1.date }
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        let recent = sorted.filter { $0.date >= cutoff }
        let older = sorted.filter { $0.date < cutoff }
        guard let recentAvg = Formulas.recentAverage(values: recent.map(\.weightKg), count: recent.count),
              let olderAvg = Formulas.recentAverage(values: older.suffix(7).map(\.weightKg), count: 7)
        else { return nil }
        return recentAvg - olderAvg
    }

    /// Media de los últimos 7 días.
    func sevenDayAverage(from logs: [BodyWeightLog]) -> Double? {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        let recent = logs.filter { $0.date >= cutoff }.map(\.weightKg)
        return Formulas.recentAverage(values: recent, count: recent.count)
    }
}
