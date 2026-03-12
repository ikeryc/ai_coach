import Foundation

enum Constants {

    // MARK: - API

    enum API {
        /// URL base de Supabase — se configura en Fase 2
        static let supabaseURL = "https://YOUR_PROJECT.supabase.co"
        /// Clave anon pública de Supabase (sin datos sensibles aquí)
        static let supabaseAnonKey = "YOUR_ANON_KEY"
        /// URL base de Open Food Facts
        static let openFoodFactsURL = "https://world.openfoodfacts.org"
        /// URL base del CDN de wger.de para GIFs de ejercicios
        static let wgerCDNURL = "https://wger.de/api/v2"
    }

    // MARK: - Entrenamiento

    enum Training {
        /// Número de sesiones consecutivas con reps en el límite superior para progresar peso
        static let setsAtTopRangeToProgress = 2
        /// Número de sesiones consecutivas sin progresión para detectar estancamiento
        static let sessionsForStagnation = 3
        /// Fatiga percibida promedio para activar deload automático
        static let fatigueThresholdForAutoDeload: Double = 7.5
        /// Fatiga percibida para sugerir deload al usuario
        static let fatigueThresholdForSuggestedDeload: Double = 6.0
        /// Caída de rendimiento (%) respecto a la semana anterior que activa deload
        static let performanceDropForDeload: Double = 0.10
        /// Porcentaje de volumen en semana de deload
        static let deloadVolumePercentage: Double = 0.50
        /// Reducción de intensidad en deload
        static let deloadIntensityReduction: Double = 0.20
        /// Intervalo de auto-guardado de sesión activa (segundos)
        static let autoSaveInterval: TimeInterval = 30
    }

    // MARK: - Nutrición

    enum Nutrition {
        /// Incremento calórico estándar cuando el peso está por debajo del objetivo
        static let caloricIncrement = 150
        /// Reducción calórica estándar cuando el peso está por encima del objetivo
        static let caloricDecrement = 100
        /// Adherencia mínima para considerar el ajuste calórico válido
        static let minimumAdherenceForAdjustment: Double = 0.80
        /// Proteína mínima en g/kg para preservar músculo en déficit
        static let minimumProteinPerKg: Double = 1.8
        /// Proteína óptima en g/kg para hipertrofia
        static let optimalProteinPerKg: Double = 2.0
        /// Proteína en g/kg para déficit / recomposición
        static let deficitProteinPerKg: Double = 2.2
        /// Porcentaje de calorías de grasa (mínimo)
        static let fatCaloriePercentage: Double = 0.25
    }

    // MARK: - UI

    enum UI {
        /// Número de semanas de historial a mostrar en gráficos por defecto
        static let defaultChartWeeks = 8
        /// Número de días de historial de peso en gráfico
        static let weightChartDays = 30
        /// Ventana de media móvil de peso (días)
        static let weightMovingAverageWindow = 7
        /// Tamaño de batch para cargar ejercicios del dataset wger
        static let exerciseBatchSize = 50
    }

    // MARK: - Claude AI

    enum AI {
        /// Modelo para chat y análisis (velocidad + calidad)
        static let chatModel = "claude-sonnet-4-6"
        /// Modelo para generación de programas (máximo razonamiento)
        static let programModel = "claude-opus-4-6"
        /// Semanas de historial de entrenamiento a incluir en contexto
        static let trainingHistoryWeeks = 4
        /// Días de historial nutricional a incluir en contexto
        static let nutritionHistoryDays = 14
        /// Días de historial de peso a incluir en contexto
        static let weightHistoryDays = 14
    }

    // MARK: - HealthKit

    enum HealthKit {
        /// Unidad de peso por defecto
        static let defaultWeightUnit = "kg"
        /// Sincronización automática de peso desde Apple Health (días hacia atrás)
        static let initialSyncDays = 90
    }

    // MARK: - SwiftData

    enum Storage {
        /// Nombre del archivo de base de datos local
        static let databaseName = "AICoach"
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let sessionDidSave = Notification.Name("sessionDidSave")
    static let weeklyAnalysisReady = Notification.Name("weeklyAnalysisReady")
    static let adaptationSuggested = Notification.Name("adaptationSuggested")
    static let newPersonalRecord = Notification.Name("newPersonalRecord")
    static let syncCompleted = Notification.Name("syncCompleted")
}
