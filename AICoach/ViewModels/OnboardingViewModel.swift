import Foundation
import SwiftData
import Observation

@Observable
final class OnboardingViewModel {

    enum Step: Int, CaseIterable {
        case basics      // edad, sexo
        case body        // peso, altura
        case goal        // objetivo principal
        case lifestyle   // experiencia, días disponibles, equipamiento
        case complete    // resumen + crear perfil

        var title: String {
            switch self {
            case .basics: "Cuéntanos sobre ti"
            case .body: "Tu cuerpo"
            case .goal: "Tu objetivo"
            case .lifestyle: "Tu estilo de entrenamiento"
            case .complete: "Todo listo"
            }
        }

        var progress: Double {
            Double(rawValue + 1) / Double(Step.allCases.count)
        }
    }

    // Estado de navegación
    var currentStep: Step = .basics

    // Datos del formulario
    var age: Int = 25
    var sex: Sex = .male
    var weightKg: Double = 75
    var heightCm: Double = 175
    var bodyFatPercentage: Double? = nil
    var primaryGoal: TrainingGoal = .hypertrophy
    var experienceLevel: ExperienceLevel = .beginner
    var availableTrainingDays: Int = 4
    var equipment: Equipment = .fullGym

    var isLoading = false
    var errorMessage: String?
    var onComplete: (() -> Void)?

    private let supabase: SupabaseService
    private let syncEngine: SyncEngine

    init(
        supabase: SupabaseService = .shared,
        syncEngine: SyncEngine = .shared
    ) {
        self.supabase = supabase
        self.syncEngine = syncEngine
    }

    // MARK: - Navegación

    var canGoNext: Bool {
        switch currentStep {
        case .basics: return age >= 13 && age <= 100
        case .body: return weightKg >= 30 && weightKg <= 300 && heightCm >= 100 && heightCm <= 250
        case .goal, .lifestyle, .complete: return true
        }
    }

    func next() {
        guard let nextStep = Step(rawValue: currentStep.rawValue + 1) else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = nextStep
        }
    }

    func back() {
        guard let prevStep = Step(rawValue: currentStep.rawValue - 1) else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = prevStep
        }
    }

    // MARK: - Crear Perfil

    func createProfile(modelContext: ModelContext) async {
        guard let userId = supabase.session?.user.id else {
            errorMessage = "Sesión no encontrada. Inicia sesión de nuevo."
            return
        }

        isLoading = true
        errorMessage = nil

        let profile = UserProfile(
            supabaseUserId: userId,
            age: age,
            sex: sex,
            weightKg: weightKg,
            heightCm: heightCm,
            bodyFatPercentage: bodyFatPercentage,
            experienceLevel: experienceLevel,
            primaryGoal: primaryGoal,
            availableTrainingDays: availableTrainingDays,
            equipment: equipment
        )

        modelContext.insert(profile)

        // Crear objetivo nutricional inicial automáticamente
        let macros = NutritionGoal.calculate(
            weightKg: weightKg,
            heightCm: heightCm,
            age: age,
            sex: sex,
            goal: primaryGoal
        )
        let nutritionGoal = NutritionGoal(
            caloriesTarget: macros.calories,
            proteinG: macros.proteinG,
            carbsG: macros.carbsG,
            fatG: macros.fatG,
            adjustmentReason: "Objetivo inicial calculado en onboarding",
            createdBy: .ruleEngine
        )
        nutritionGoal.userProfile = profile
        modelContext.insert(nutritionGoal)

        do {
            try modelContext.save()
        } catch {
            await MainActor.run {
                errorMessage = "Error al guardar el perfil localmente: \(error.localizedDescription)"
                isLoading = false
            }
            return
        }

        // Sync a Supabase en background (no bloquea si falla)
        await syncEngine.syncProfile(profile)
        await syncEngine.syncNutritionGoal(nutritionGoal)

        await MainActor.run {
            isLoading = false
            onComplete?()
        }
    }

    // MARK: - Resumen calculado

    var tdeeEstimate: Int {
        Int(Formulas.tdee(
            weightKg: weightKg,
            heightCm: heightCm,
            age: age,
            sex: sex,
            activityLevel: activityLevelForDays(availableTrainingDays)
        ))
    }

    var recommendedCalories: Int {
        let tdee = Double(tdeeEstimate)
        return switch primaryGoal {
        case .hypertrophy: Int(tdee + 300)
        case .strength: Int(tdee + 200)
        case .fatLoss: Int(tdee - 400)
        case .recomposition: Int(tdee)
        }
    }

    var recommendedProtein: Int {
        let multiplier: Double = (primaryGoal == .fatLoss || primaryGoal == .recomposition) ? 2.2 : 2.0
        return Int(weightKg * multiplier)
    }

    private func activityLevelForDays(_ days: Int) -> ActivityLevel {
        switch days {
        case 0...1: .sedentary
        case 2...3: .lightlyActive
        case 4...5: .moderatelyActive
        default: .veryActive
        }
    }
}
