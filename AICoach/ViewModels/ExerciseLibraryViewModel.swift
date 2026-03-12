import Foundation
import SwiftData
import Observation

@Observable
final class ExerciseLibraryViewModel {

    // Filtros activos
    var searchText = ""
    var selectedMuscle: MuscleGroup? = nil
    var selectedEquipment: Equipment? = nil
    var selectedType: ExerciseType? = nil
    var showFavoritesOnly = false

    // Favoritos — en Fase 3 los guardamos en UserDefaults (simple)
    private var favoriteIds: Set<String> {
        get { Set(UserDefaults.standard.stringArray(forKey: "favorite_exercise_ids") ?? []) }
        set { UserDefaults.standard.set(Array(newValue), forKey: "favorite_exercise_ids") }
    }

    var hasActiveFilters: Bool {
        selectedMuscle != nil || selectedEquipment != nil || selectedType != nil || showFavoritesOnly
    }

    // MARK: - Filtrado

    func filtered(_ exercises: [Exercise]) -> [Exercise] {
        exercises.filter { exercise in
            // Búsqueda por texto
            if !searchText.isEmpty {
                let query = searchText.lowercased()
                guard exercise.name.lowercased().contains(query) ||
                      exercise.primaryMuscleGroup.displayName.lowercased().contains(query)
                else { return false }
            }
            // Filtro músculo
            if let muscle = selectedMuscle, exercise.primaryMuscleGroup != muscle { return false }
            // Filtro equipamiento
            if let eq = selectedEquipment, exercise.equipmentRequired != eq { return false }
            // Filtro tipo
            if let type = selectedType, exercise.exerciseType != type { return false }
            // Favoritos
            if showFavoritesOnly, !isFavorite(exercise) { return false }
            return true
        }
        .sorted { $0.name < $1.name }
    }

    // MARK: - Favoritos

    func isFavorite(_ exercise: Exercise) -> Bool {
        favoriteIds.contains(exercise.id.uuidString)
    }

    func toggleFavorite(_ exercise: Exercise) {
        var ids = favoriteIds
        if ids.contains(exercise.id.uuidString) {
            ids.remove(exercise.id.uuidString)
        } else {
            ids.insert(exercise.id.uuidString)
        }
        favoriteIds = ids
    }

    // MARK: - Agrupación por músculo para índice lateral

    func grouped(_ exercises: [Exercise]) -> [(key: MuscleGroup, exercises: [Exercise])] {
        let filtered = self.filtered(exercises)
        let grouped = Dictionary(grouping: filtered, by: \.primaryMuscleGroup)
        return grouped
            .map { (key: $0.key, exercises: $0.value.sorted { $0.name < $1.name }) }
            .sorted { $0.key.displayName < $1.key.displayName }
    }

    func clearFilters() {
        selectedMuscle = nil
        selectedEquipment = nil
        selectedType = nil
        showFavoritesOnly = false
    }
}
