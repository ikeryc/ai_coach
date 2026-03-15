import Foundation
import SwiftData

/// Motor de adaptación determinístico.
/// Analiza las últimas WeeklyMetrics y crea AdaptationEvent pendientes de aprobación.
/// Nunca aplica cambios sin que el usuario los confirme.
final class AdaptationEngine {

    static let shared = AdaptationEngine()

    // MARK: - Análisis

    /// Crea AdaptationEvent para las reglas que se disparan. Devuelve los eventos creados.
    @discardableResult
    func analyze(profile: UserProfile, modelContext: ModelContext) -> [AdaptationEvent] {
        let sortedMetrics = profile.weeklyMetrics.sorted { $0.weekStartDate > $1.weekStartDate }
        guard let latest = sortedMetrics.first else { return [] }
        let previous = sortedMetrics.dropFirst().first

        // Tipos con evento pendiente ya existente (evitar duplicados)
        let pendingTypes = Set(
            profile.adaptationEvents
                .filter { !$0.userApproved }
                .map { $0.adaptationType }
        )

        var newEvents: [AdaptationEvent] = []

        // Regla 1: ajuste calórico basado en cambio de peso
        if !pendingTypes.contains(.caloriesUp) && !pendingTypes.contains(.caloriesDown) {
            if let event = checkCaloricAdjustment(latest: latest, profile: profile) {
                newEvents.append(event)
            }
        }

        // Regla 2: deload por caída de rendimiento
        if !pendingTypes.contains(.deload) {
            if let event = checkPerformanceDrop(latest: latest, previous: previous) {
                newEvents.append(event)
            }
        }

        // Regla 3: reducción de volumen por adherencia baja
        if !pendingTypes.contains(.volumeDown) {
            if let event = checkLowAdherence(latest: latest) {
                newEvents.append(event)
            }
        }

        for event in newEvents {
            event.userProfile = profile
            modelContext.insert(event)
        }
        try? modelContext.save()
        return newEvents
    }

    // MARK: - Reglas individuales

    private func checkCaloricAdjustment(latest: WeeklyMetrics, profile: UserProfile) -> AdaptationEvent? {
        guard let weightChange = latest.weightChangeVsPrevWeek else { return nil }

        let latestWeight = profile.bodyWeightLogs
            .sorted { $0.date < $1.date }.last?.weightKg ?? profile.weightKg

        let range = profile.primaryGoal.weeklyWeightChangeRange
        let lowerTarget = latestWeight * range.lowerBound
        let upperTarget = latestWeight * range.upperBound

        guard let activeGoal = profile.nutritionGoals
            .filter({ $0.isActive })
            .sorted(by: { $0.startDate > $1.startDate })
            .first else { return nil }

        let prevCal = activeGoal.caloriesTarget
        let type: AdaptationType
        let newCal: Int
        let reason: String

        if weightChange < lowerTarget {
            switch profile.primaryGoal {
            case .hypertrophy, .strength:
                type = .caloriesUp
                newCal = prevCal + Constants.Nutrition.caloricIncrement
                reason = "Tu peso cambió \(String(format: "%.2f", weightChange)) kg esta semana (objetivo mínimo: \(String(format: "+%.2f", lowerTarget)) kg). Subimos +\(Constants.Nutrition.caloricIncrement) kcal para favorecer el crecimiento muscular."
            case .fatLoss:
                type = .caloriesDown
                newCal = prevCal - Constants.Nutrition.caloricDecrement
                reason = "La pérdida de peso (\(String(format: "%.2f", weightChange)) kg/sem) está por debajo del objetivo (\(String(format: "%.2f", lowerTarget)) kg/sem). Bajamos -\(Constants.Nutrition.caloricDecrement) kcal para acelerar el progreso."
            case .recomposition:
                return nil
            }
        } else if weightChange > upperTarget {
            switch profile.primaryGoal {
            case .fatLoss:
                type = .caloriesUp
                newCal = prevCal + Constants.Nutrition.caloricIncrement
                reason = "La pérdida de peso (\(String(format: "%.2f", weightChange)) kg/sem) es demasiado rápida. Subimos +\(Constants.Nutrition.caloricIncrement) kcal para preservar masa muscular."
            case .hypertrophy, .strength:
                type = .caloriesDown
                newCal = prevCal - Constants.Nutrition.caloricDecrement
                reason = "El aumento de peso (\(String(format: "+%.2f", weightChange)) kg/sem) supera el objetivo (\(String(format: "+%.2f", upperTarget)) kg/sem). Bajamos -\(Constants.Nutrition.caloricDecrement) kcal para limitar la ganancia de grasa."
            case .recomposition:
                return nil
            }
        } else {
            return nil
        }

        let prevData = try? JSONEncoder().encode(["calories": prevCal])
        let newData  = try? JSONEncoder().encode(["calories": newCal])

        return AdaptationEvent(
            adaptationType: type,
            previousValue: prevData,
            newValue: newData,
            triggerReason: reason,
            triggeredBy: .ruleEngine
        )
    }

    private func checkPerformanceDrop(latest: WeeklyMetrics, previous: WeeklyMetrics?) -> AdaptationEvent? {
        guard let prev = previous,
              let latestRMs = latest.decoded1RM(),
              let prevRMs   = prev.decoded1RM(),
              !latestRMs.isEmpty, !prevRMs.isEmpty else { return nil }

        let common = Set(latestRMs.keys).intersection(Set(prevRMs.keys))
        guard !common.isEmpty else { return nil }

        let avgLatest = common.compactMap { latestRMs[$0] }.reduce(0, +) / Double(common.count)
        let avgPrev   = common.compactMap { prevRMs[$0] }.reduce(0, +)   / Double(common.count)

        guard avgPrev > 0 else { return nil }
        let drop = (avgPrev - avgLatest) / avgPrev
        guard drop > Constants.Training.performanceDropForDeload else { return nil }

        let reason = "Tu rendimiento (e1RM medio) ha caído un \(String(format: "%.0f", drop * 100))% respecto a la semana anterior. Una semana de descarga mejorará la recuperación del sistema nervioso central."

        return AdaptationEvent(
            adaptationType: .deload,
            triggerReason: reason,
            triggeredBy: .ruleEngine
        )
    }

    private func checkLowAdherence(latest: WeeklyMetrics) -> AdaptationEvent? {
        guard latest.trainingSessionsPlanned >= 3 else { return nil }
        guard latest.adherenceRatio < 0.5 else { return nil }

        let reason = "Completaste \(latest.trainingSessionsCompleted)/\(latest.trainingSessionsPlanned) sesiones (\(latest.adherencePercentage)% de adherencia). Reducir el número de entrenamientos puede mejorar la constancia a largo plazo."

        return AdaptationEvent(
            adaptationType: .volumeDown,
            triggerReason: reason,
            triggeredBy: .ruleEngine
        )
    }

    // MARK: - Aplicar adaptación aprobada

    func apply(_ event: AdaptationEvent, profile: UserProfile, modelContext: ModelContext) {
        switch event.adaptationType {
        case .caloriesUp, .caloriesDown:
            applyCalorieChange(event: event, profile: profile, modelContext: modelContext)
        default:
            break // Deload y volumeDown son sugerencias; el usuario actúa manualmente
        }
        event.userApproved = true
        try? modelContext.save()
    }

    private func applyCalorieChange(event: AdaptationEvent, profile: UserProfile, modelContext: ModelContext) {
        guard let newData  = event.newValue,
              let newDict  = try? JSONDecoder().decode([String: Int].self, from: newData),
              let newCal   = newDict["calories"],
              let active   = profile.nutritionGoals
                  .filter({ $0.isActive })
                  .sorted(by: { $0.startDate > $1.startDate })
                  .first else { return }

        // Cerrar el objetivo actual
        active.endDate = .now

        // Calcular nuevos macros: proteína fija, escalar carbos y grasa
        let ratio = Double(newCal) / Double(active.caloriesTarget)
        let newGoal = NutritionGoal(
            caloriesTarget: newCal,
            proteinG: active.proteinG,
            carbsG: max(0, Int(Double(active.carbsG) * ratio)),
            fatG: max(0, Int(Double(active.fatG) * ratio)),
            adjustmentReason: event.triggerReason,
            createdBy: .ruleEngine
        )
        newGoal.userProfile = profile
        modelContext.insert(newGoal)
    }
}
