import Foundation
import HealthKit
import Observation

@Observable
final class HealthKitService {

    static let shared = HealthKitService()

    private let store = HKHealthStore()
    private(set) var isAuthorized = false

    private let weightType = HKQuantityType(.bodyMass)

    // MARK: - Autorización

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    func requestAuthorization() async -> Bool {
        guard isAvailable else { return false }
        do {
            try await store.requestAuthorization(
                toShare: [weightType],
                read: [weightType]
            )
            isAuthorized = true
            return true
        } catch {
            return false
        }
    }

    // MARK: - Lectura de peso

    /// Lee el historial de peso de los últimos N días desde Apple Health.
    func fetchWeightHistory(days: Int = Constants.HealthKit.initialSyncDays) async -> [(date: Date, weightKg: Double)] {
        guard isAvailable else { return [] }

        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: .now) ?? .now
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: .now)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: weightType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, _ in
                let results = (samples as? [HKQuantitySample] ?? []).map { sample in
                    (
                        date: sample.startDate,
                        weightKg: sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
                    )
                }
                continuation.resume(returning: results)
            }
            store.execute(query)
        }
    }

    /// Lee el peso más reciente disponible en Apple Health.
    func fetchLatestWeight() async -> Double? {
        let results = await fetchWeightHistory(days: 7)
        return results.last?.weightKg
    }

    // MARK: - Escritura de peso

    /// Escribe un nuevo registro de peso en Apple Health.
    func saveWeight(_ weightKg: Double, date: Date = .now) async -> Bool {
        guard isAvailable else { return false }
        let quantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: weightKg)
        let sample = HKQuantitySample(
            type: weightType,
            quantity: quantity,
            start: date,
            end: date
        )
        do {
            try await store.save(sample)
            return true
        } catch {
            return false
        }
    }
}
