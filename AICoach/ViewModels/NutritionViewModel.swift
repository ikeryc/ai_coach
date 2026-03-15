import Foundation
import SwiftData
import Observation

@Observable
final class NutritionViewModel {

    var selectedDate: Date = Calendar.current.startOfDay(for: .now)
    var searchResults: [FoodItemDTO] = []
    var isLoadingSearch = false
    var searchError: String?

    private let offService = OpenFoodFactsService.shared

    // MARK: - Date navigation

    var dateDisplay: String {
        let cal = Calendar.current
        if cal.isDateInToday(selectedDate) { return "Hoy" }
        if cal.isDateInYesterday(selectedDate) { return "Ayer" }
        return selectedDate.formatted(date: .abbreviated, time: .omitted)
    }

    var canGoForward: Bool {
        !Calendar.current.isDateInToday(selectedDate)
    }

    func goToPreviousDay() {
        selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
    }

    func goToNextDay() {
        guard canGoForward else { return }
        selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
    }

    // MARK: - Daily data

    func mealsForDate(from allMeals: [MealLog]) -> [MealLog] {
        allMeals
            .filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
            .sorted { $0.mealType.sortOrder < $1.mealType.sortOrder }
    }

    func meal(type: MealType, from allMeals: [MealLog]) -> MealLog? {
        mealsForDate(from: allMeals).first { $0.mealType == type }
    }

    func dailyTotals(from meals: [MealLog]) -> (calories: Double, protein: Double, carbs: Double, fat: Double) {
        let dayMeals = mealsForDate(from: meals)
        return (
            calories: dayMeals.reduce(0) { $0 + $1.totalCalories },
            protein:  dayMeals.reduce(0) { $0 + $1.totalProtein },
            carbs:    dayMeals.reduce(0) { $0 + $1.totalCarbs },
            fat:      dayMeals.reduce(0) { $0 + $1.totalFat }
        )
    }

    func activeGoal(from goals: [NutritionGoal]) -> NutritionGoal? {
        goals.filter { $0.isActive }.sorted { $0.startDate > $1.startDate }.first
    }

    // MARK: - Meal management

    func getOrCreateMeal(
        type: MealType,
        allMeals: [MealLog],
        profile: UserProfile?,
        modelContext: ModelContext
    ) -> MealLog {
        if let existing = meal(type: type, from: allMeals) { return existing }
        let newMeal = MealLog(date: selectedDate, mealType: type)
        newMeal.userProfile = profile
        modelContext.insert(newMeal)
        try? modelContext.save()
        return newMeal
    }

    func addFoodEntry(food: FoodItem, grams: Double, toMeal meal: MealLog, modelContext: ModelContext) {
        let entry = MealFoodEntry(quantityG: grams, foodItem: food)
        entry.meal = meal
        modelContext.insert(entry)
        try? modelContext.save()
    }

    func deleteEntry(_ entry: MealFoodEntry, modelContext: ModelContext) {
        modelContext.delete(entry)
        try? modelContext.save()
    }

    // MARK: - FoodItem cache (evita duplicados por externalId o barcode)

    func findOrCacheFoodItem(dto: FoodItemDTO, modelContext: ModelContext) -> FoodItem {
        if let externalId = dto.externalId {
            let desc = FetchDescriptor<FoodItem>(predicate: #Predicate { $0.externalId == externalId })
            if let existing = try? modelContext.fetch(desc), let first = existing.first { return first }
        }
        if let barcode = dto.barcode {
            let desc = FetchDescriptor<FoodItem>(predicate: #Predicate { $0.barcode == barcode })
            if let existing = try? modelContext.fetch(desc), let first = existing.first { return first }
        }
        let item = dto.toFoodItem()
        modelContext.insert(item)
        try? modelContext.save()
        return item
    }

    // MARK: - Food search

    func searchFood(query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { searchResults = []; return }
        isLoadingSearch = true
        searchError = nil
        do {
            searchResults = try await offService.search(query: trimmed)
        } catch {
            searchError = "Error al buscar: \(error.localizedDescription)"
            searchResults = []
        }
        isLoadingSearch = false
    }

    func lookupBarcode(_ barcode: String) async -> FoodItemDTO? {
        isLoadingSearch = true
        searchError = nil
        defer { isLoadingSearch = false }
        do {
            return try await offService.lookup(barcode: barcode)
        } catch {
            searchError = "Código no encontrado en la base de datos"
            return nil
        }
    }
}
