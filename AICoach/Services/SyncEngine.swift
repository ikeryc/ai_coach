import Foundation
import SwiftData
import Observation

/// Motor de sincronización offline-first.
/// Estrategia: last-write-wins por `updatedAt`. El cliente es la fuente de verdad durante uso offline.
/// Al recuperar conexión, sube cambios locales y baja cambios del servidor.
@Observable
final class SyncEngine {

    static let shared = SyncEngine()

    private let supabase: SupabaseService
    private(set) var isSyncing = false
    private(set) var lastSyncDate: Date?
    var syncError: String?

    init(supabase: SupabaseService = .shared) {
        self.supabase = supabase
    }

    // MARK: - Sync de Perfil

    /// Sube el perfil del usuario a Supabase (upsert).
    func syncProfile(_ profile: UserProfile) async {
        guard supabase.isAuthenticated else { return }
        do {
            let dto = UserProfileDTO(from: profile)
            try await supabase.update(
                dto,
                in: "user_profiles",
                matching: "user_id=eq.\(profile.supabaseUserId)"
            )
        } catch SupabaseError.httpError(404, _) {
            // Perfil no existe aún — insertar
            do {
                let dto = UserProfileDTO(from: profile)
                try await supabase.insert(dto, into: "user_profiles")
            } catch {
                syncError = error.localizedDescription
            }
        } catch {
            syncError = error.localizedDescription
        }
    }

    /// Sube una sesión de entrenamiento completada a Supabase.
    func syncSession(_ session: TrainingSession) async {
        guard supabase.isAuthenticated,
              let userId = supabase.session?.user.id else { return }
        do {
            let dto = TrainingSessionDTO(from: session, userId: userId)
            try await supabase.insert(dto, into: "training_sessions")

            for set in session.sets {
                let setDTO = ExerciseSetDTO(from: set, sessionId: session.id.uuidString)
                try await supabase.insert(setDTO, into: "exercise_sets")
            }
        } catch {
            syncError = error.localizedDescription
        }
    }

    /// Sube un registro de peso corporal a Supabase.
    func syncWeightLog(_ log: BodyWeightLog) async {
        guard supabase.isAuthenticated,
              let userId = supabase.session?.user.id else { return }
        do {
            let dto = BodyWeightLogDTO(from: log, userId: userId)
            try await supabase.insert(dto, into: "body_weight_logs")
        } catch {
            syncError = error.localizedDescription
        }
    }

    /// Sube el objetivo nutricional actual a Supabase.
    func syncNutritionGoal(_ goal: NutritionGoal) async {
        guard supabase.isAuthenticated,
              let userId = supabase.session?.user.id else { return }
        do {
            let dto = NutritionGoalDTO(from: goal, userId: userId)
            try await supabase.insert(dto, into: "nutrition_goals")
        } catch {
            syncError = error.localizedDescription
        }
    }

    /// Sube el log de nutrición diario a Supabase.
    func syncNutritionLog(_ log: NutritionLog) async {
        guard supabase.isAuthenticated,
              let userId = supabase.session?.user.id else { return }
        do {
            let dto = NutritionLogDTO(from: log, userId: userId)
            try await supabase.insert(dto, into: "nutrition_logs")
        } catch {
            syncError = error.localizedDescription
        }
    }
}

// MARK: - DTOs (Data Transfer Objects para Supabase)

struct UserProfileDTO: Codable {
    let userId: String
    let age: Int
    let sex: String
    let weightKg: Double
    let heightCm: Double
    let bodyFatPercentage: Double?
    let experienceLevel: String
    let primaryGoal: String
    let availableTrainingDays: Int
    let equipment: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case age
        case sex
        case weightKg = "weight_kg"
        case heightCm = "height_cm"
        case bodyFatPercentage = "body_fat_percentage"
        case experienceLevel = "experience_level"
        case primaryGoal = "primary_goal"
        case availableTrainingDays = "available_training_days"
        case equipment
        case updatedAt = "updated_at"
    }

    init(from profile: UserProfile) {
        self.userId = profile.supabaseUserId
        self.age = profile.age
        self.sex = profile.sex.rawValue
        self.weightKg = profile.weightKg
        self.heightCm = profile.heightCm
        self.bodyFatPercentage = profile.bodyFatPercentage
        self.experienceLevel = profile.experienceLevel.rawValue
        self.primaryGoal = profile.primaryGoal.rawValue
        self.availableTrainingDays = profile.availableTrainingDays
        self.equipment = profile.equipment.rawValue
        self.updatedAt = ISO8601DateFormatter().string(from: profile.updatedAt)
    }
}

struct TrainingSessionDTO: Codable {
    let id: String
    let userId: String
    let workoutTemplateId: String?
    let date: String
    let startedAt: String?
    let endedAt: String?
    let perceivedFatigue: Int?
    let notes: String
    let completed: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case workoutTemplateId = "workout_template_id"
        case date
        case startedAt = "started_at"
        case endedAt = "ended_at"
        case perceivedFatigue = "perceived_fatigue"
        case notes
        case completed
    }

    init(from session: TrainingSession, userId: String) {
        let fmt = ISO8601DateFormatter()
        self.id = session.id.uuidString
        self.userId = userId
        self.workoutTemplateId = session.workoutTemplate?.id.uuidString
        self.date = fmt.string(from: session.date)
        self.startedAt = session.startedAt.map { fmt.string(from: $0) }
        self.endedAt = session.endedAt.map { fmt.string(from: $0) }
        self.perceivedFatigue = session.perceivedFatigue
        self.notes = session.notes
        self.completed = session.completed
    }
}

struct ExerciseSetDTO: Codable {
    let id: String
    let sessionId: String
    let exerciseId: String?
    let setNumber: Int
    let weightKg: Double
    let reps: Int
    let rirActual: Int?
    let isWarmup: Bool
    let loggedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case sessionId = "session_id"
        case exerciseId = "exercise_id"
        case setNumber = "set_number"
        case weightKg = "weight_kg"
        case reps
        case rirActual = "rir_actual"
        case isWarmup = "is_warmup"
        case loggedAt = "logged_at"
    }

    init(from set: ExerciseSet, sessionId: String) {
        let fmt = ISO8601DateFormatter()
        self.id = set.id.uuidString
        self.sessionId = sessionId
        self.exerciseId = set.exercise?.id.uuidString
        self.setNumber = set.setNumber
        self.weightKg = set.weightKg
        self.reps = set.reps
        self.rirActual = set.rirActual
        self.isWarmup = set.isWarmup
        self.loggedAt = fmt.string(from: set.loggedAt)
    }
}

struct BodyWeightLogDTO: Codable {
    let id: String
    let userId: String
    let date: String
    let weightKg: Double
    let source: String
    let notes: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case date
        case weightKg = "weight_kg"
        case source
        case notes
    }

    init(from log: BodyWeightLog, userId: String) {
        self.id = log.id.uuidString
        self.userId = userId
        self.date = ISO8601DateFormatter().string(from: log.date)
        self.weightKg = log.weightKg
        self.source = log.source.rawValue
        self.notes = log.notes
    }
}

struct NutritionGoalDTO: Codable {
    let id: String
    let userId: String
    let startDate: String
    let endDate: String?
    let caloriesTarget: Int
    let proteinG: Int
    let carbsG: Int
    let fatG: Int
    let adjustmentReason: String?
    let createdBy: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case startDate = "start_date"
        case endDate = "end_date"
        case caloriesTarget = "calories_target"
        case proteinG = "protein_g"
        case carbsG = "carbs_g"
        case fatG = "fat_g"
        case adjustmentReason = "adjustment_reason"
        case createdBy = "created_by"
    }

    init(from goal: NutritionGoal, userId: String) {
        let fmt = ISO8601DateFormatter()
        self.id = goal.id.uuidString
        self.userId = userId
        self.startDate = fmt.string(from: goal.startDate)
        self.endDate = goal.endDate.map { fmt.string(from: $0) }
        self.caloriesTarget = goal.caloriesTarget
        self.proteinG = goal.proteinG
        self.carbsG = goal.carbsG
        self.fatG = goal.fatG
        self.adjustmentReason = goal.adjustmentReason
        self.createdBy = goal.createdBy.rawValue
    }
}

struct NutritionLogDTO: Codable {
    let id: String
    let userId: String
    let date: String
    let calories: Int
    let proteinG: Double
    let carbsG: Double
    let fatG: Double
    let adherencePercentage: Double?
    let notes: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case date
        case calories
        case proteinG = "protein_g"
        case carbsG = "carbs_g"
        case fatG = "fat_g"
        case adherencePercentage = "adherence_percentage"
        case notes
    }

    init(from log: NutritionLog, userId: String) {
        self.id = log.id.uuidString
        self.userId = userId
        self.date = ISO8601DateFormatter().string(from: log.date)
        self.calories = log.calories
        self.proteinG = log.proteinG
        self.carbsG = log.carbsG
        self.fatG = log.fatG
        self.adherencePercentage = log.adherencePercentage
        self.notes = log.notes
    }
}
