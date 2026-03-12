import Foundation
import SwiftData

/// Carga la biblioteca de ejercicios desde el bundle local (wger_exercises.json)
/// en el primer arranque de la app. Los GIFs se descargan bajo demanda desde el CDN de wger.de.
final class WgerService {

    static let shared = WgerService()

    private let seededKey = "wger_exercises_seeded_v1"

    var isSeeded: Bool {
        UserDefaults.standard.bool(forKey: seededKey)
    }

    // MARK: - Seed inicial

    /// Carga los ejercicios del bundle JSON en SwiftData si no se ha hecho antes.
    /// Llama desde AICoachApp.init() en un Task en background.
    func seedIfNeeded(modelContext: ModelContext) async {
        guard !isSeeded else { return }

        guard let url = Bundle.main.url(forResource: "wger_exercises", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("[WgerService] wger_exercises.json no encontrado en el bundle.")
            return
        }

        do {
            let response = try JSONDecoder().decode(WgerExerciseResponse.self, from: data)
            var insertCount = 0

            for wgerEx in response.results {
                guard let name = wgerEx.translations?.first(where: { $0.language == 2 })?.name,
                      !name.isEmpty else { continue }

                let exercise = Exercise(
                    wgerId: wgerEx.id,
                    name: name,
                    primaryMuscleGroup: mapMuscle(wgerEx.muscles?.first?.nameEn),
                    secondaryMuscleGroups: (wgerEx.musclesSecondary ?? []).compactMap { mapMuscle($0.nameEn) },
                    equipmentRequired: mapEquipment(wgerEx.equipment?.first?.name),
                    exerciseType: (wgerEx.category?.name == "Cardio") ? .isolation : .compound,
                    instructions: wgerEx.translations?.first(where: { $0.language == 2 })?.description ?? "",
                    gifURL: wgerEx.images?.first?.image,
                    thumbnailURL: wgerEx.images?.first(where: { $0.isMain == true })?.image,
                    isCustom: false,
                    ownerUserId: nil
                )
                modelContext.insert(exercise)
                insertCount += 1
            }

            try modelContext.save()
            UserDefaults.standard.set(true, forKey: seededKey)
            print("[WgerService] \(insertCount) ejercicios importados.")
        } catch {
            print("[WgerService] Error al parsear JSON: \(error)")
        }
    }

    // MARK: - Mapeos

    private func mapMuscle(_ name: String?) -> MuscleGroup {
        switch name?.lowercased() {
        case "biceps brachii", "biceps": .biceps
        case "triceps brachii", "triceps": .triceps
        case "pectoralis major", "chest": .chest
        case "latissimus dorsi", "back", "lats": .back
        case "deltoid", "shoulders": .shoulders
        case "quadriceps femoris", "quadriceps": .quads
        case "biceps femoris", "hamstrings": .hamstrings
        case "gluteus maximus", "glutes": .glutes
        case "gastrocnemius", "calves": .calves
        case "rectus abdominis", "abs", "core": .core
        case "trapezius", "traps": .traps
        case "brachioradialis", "forearms": .forearms
        default: .core
        }
    }

    private func mapEquipment(_ name: String?) -> Equipment {
        switch name?.lowercased() {
        case "dumbbell": .dumbbellsOnly
        case "none (bodyweight)": .home
        default: .fullGym
        }
    }
}

// MARK: - Wger JSON Models

struct WgerExerciseResponse: Decodable {
    let results: [WgerExercise]
}

struct WgerExercise: Decodable {
    let id: Int
    let category: WgerCategory?
    let muscles: [WgerMuscle]?
    let musclesSecondary: [WgerMuscle]?
    let equipment: [WgerEquipment]?
    let images: [WgerImage]?
    let translations: [WgerTranslation]?

    enum CodingKeys: String, CodingKey {
        case id, category, muscles, equipment, images, translations
        case musclesSecondary = "muscles_secondary"
    }
}

struct WgerCategory: Decodable { let name: String }
struct WgerMuscle: Decodable {
    let nameEn: String?
    enum CodingKeys: String, CodingKey { case nameEn = "name_en" }
}
struct WgerEquipment: Decodable { let name: String }
struct WgerImage: Decodable {
    let image: String
    let isMain: Bool?
    enum CodingKeys: String, CodingKey { case image; case isMain = "is_main" }
}
struct WgerTranslation: Decodable {
    let language: Int
    let name: String
    let description: String
}
