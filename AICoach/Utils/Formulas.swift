import Foundation

/// Fórmulas determinísticas de fitness. Sin lógica de negocio aquí — solo cálculos puros.
enum Formulas {

    // MARK: - Fuerza

    /// e1RM (1 Rep Max estimado) usando fórmula de Epley.
    /// Epley: weight × (1 + reps/30)
    /// Válido para reps en el rango 1-10.
    static func epley(weight: Double, reps: Int) -> Double {
        guard reps > 0 else { return 0 }
        guard reps > 1 else { return weight }
        return weight * (1.0 + Double(reps) / 30.0)
    }

    /// Fórmula de Brzycki: weight / (1.0278 - 0.0278 × reps)
    /// Alternativa, más precisa para rangos bajos (1-10 reps).
    static func brzycki(weight: Double, reps: Int) -> Double {
        guard reps > 0, reps < 37 else { return weight }
        guard reps > 1 else { return weight }
        return weight / (1.0278 - 0.0278 * Double(reps))
    }

    /// Peso a usar para un rep target dado un 1RM y porcentaje de intensidad
    static func weightForReps(oneRepMax: Double, targetReps: Int) -> Double {
        // Percentages table basada en Prilepin y Brzycki inversa
        let repsToPercentage: [Int: Double] = [
            1: 1.0, 2: 0.95, 3: 0.93, 4: 0.90, 5: 0.87,
            6: 0.85, 7: 0.83, 8: 0.80, 9: 0.77, 10: 0.75,
            12: 0.70, 15: 0.65, 20: 0.60
        ]
        let percentage = repsToPercentage[targetReps] ?? (1.0 - Double(targetReps - 1) * 0.025)
        return oneRepMax * percentage
    }

    // MARK: - Metabolismo Basal

    /// BMR usando fórmula de Mifflin-St Jeor (la más precisa con evidencia actual).
    /// Hombre: 10×peso + 6.25×altura − 5×edad + 5
    /// Mujer:  10×peso + 6.25×altura − 5×edad − 161
    static func bmr(weightKg: Double, heightCm: Double, age: Int, sex: Sex) -> Double {
        let base = (10 * weightKg) + (6.25 * heightCm) - (5.0 * Double(age))
        return sex == .male ? base + 5 : base - 161
    }

    /// TDEE (Total Daily Energy Expenditure) = BMR × factor de actividad
    static func tdee(
        weightKg: Double,
        heightCm: Double,
        age: Int,
        sex: Sex,
        activityLevel: ActivityLevel
    ) -> Double {
        let bmrValue = bmr(weightKg: weightKg, heightCm: heightCm, age: age, sex: sex)
        return bmrValue * activityLevel.multiplier
    }

    // MARK: - Composición Corporal

    /// Peso libre de grasa (Lean Body Mass)
    static func leanBodyMass(weightKg: Double, bodyFatPercentage: Double) -> Double {
        weightKg * (1 - bodyFatPercentage / 100)
    }

    // MARK: - IMC (BMI)

    static func bmi(weightKg: Double, heightCm: Double) -> Double {
        let heightM = heightCm / 100
        return weightKg / (heightM * heightM)
    }

    static func bmiCategory(bmi: Double) -> String {
        switch bmi {
        case ..<18.5: "Bajo peso"
        case 18.5..<25: "Normal"
        case 25..<30: "Sobrepeso"
        default: "Obesidad"
        }
    }

    // MARK: - Medias móviles

    /// Media móvil simple de N días para un array de valores con fecha.
    /// Retorna el promedio de los últimos `days` valores, o nil si no hay suficientes datos.
    static func movingAverage(values: [Double], window: Int) -> [Double?] {
        guard !values.isEmpty, window > 0 else { return [] }
        return values.enumerated().map { index, _ in
            let start = max(0, index - window + 1)
            let slice = Array(values[start...index])
            return slice.reduce(0, +) / Double(slice.count)
        }
    }

    /// Media de los últimos N valores de un array
    static func recentAverage(values: [Double], count: Int) -> Double? {
        guard !values.isEmpty else { return nil }
        let slice = Array(values.suffix(count))
        return slice.reduce(0, +) / Double(slice.count)
    }

    // MARK: - Progresión de carga

    /// Incremento estándar de peso sugerido para un ejercicio.
    /// Barras: +2.5kg (mínimo) para aislamiento, +5kg para compuestos
    /// Mancuernas: siguiente mancuerna disponible (+2kg habitualmente)
    static func standardWeightIncrement(exerciseType: ExerciseType, usesDumbbells: Bool) -> Double {
        if usesDumbbells {
            return 2.0
        }
        return exerciseType == .compound ? 5.0 : 2.5
    }

    // MARK: - Volumen de entrenamiento

    /// Volumen total (sets × reps × kg) de un grupo de sets
    static func totalVolume(sets: [(weight: Double, reps: Int)]) -> Double {
        sets.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
    }

    // MARK: - Déficit / Superávit calórico

    /// Kcal necesarias para cambiar 1kg de peso corporal (~7700 kcal)
    static let kcalPerKg: Double = 7700

    /// Déficit/superávit calórico diario necesario para alcanzar un cambio de peso semanal objetivo
    static func dailyCaloricAdjustment(weeklyWeightChangeKg: Double) -> Double {
        (weeklyWeightChangeKg * kcalPerKg) / 7.0
    }
}
