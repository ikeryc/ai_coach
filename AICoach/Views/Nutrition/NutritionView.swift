import SwiftUI
import SwiftData

struct NutritionView: View {

    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query private var allMeals: [MealLog]
    @Query private var allGoals: [NutritionGoal]

    @State private var viewModel = NutritionViewModel()
    @State private var addingToMealType: MealType?

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    dateNavigator
                    dailySummaryCard
                    mealSections
                }
                .padding(.horizontal)
                .padding(.top)
                .padding(.bottom, 20)
            }
            .navigationTitle("Nutrición")
            .sheet(item: $addingToMealType) { mealType in
                AddFoodEntrySheet(
                    mealType: mealType,
                    viewModel: viewModel,
                    onAdd: { dto, grams in
                        let food = viewModel.findOrCacheFoodItem(dto: dto, modelContext: modelContext)
                        let meal = viewModel.getOrCreateMeal(
                            type: mealType,
                            allMeals: allMeals,
                            profile: profile,
                            modelContext: modelContext
                        )
                        viewModel.addFoodEntry(food: food, grams: grams, toMeal: meal, modelContext: modelContext)
                    }
                )
            }
        }
    }

    // MARK: - Date navigator

    private var dateNavigator: some View {
        HStack {
            Button {
                viewModel.goToPreviousDay()
            } label: {
                Image(systemName: "chevron.left")
                    .fontWeight(.semibold)
                    .foregroundStyle(.blue)
                    .frame(width: 36, height: 36)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(Circle())
            }

            Spacer()

            Text(viewModel.dateDisplay)
                .font(.headline)

            Spacer()

            Button {
                viewModel.goToNextDay()
            } label: {
                Image(systemName: "chevron.right")
                    .fontWeight(.semibold)
                    .foregroundStyle(viewModel.canGoForward ? .blue : .secondary)
                    .frame(width: 36, height: 36)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(Circle())
            }
            .disabled(!viewModel.canGoForward)
        }
    }

    // MARK: - Daily summary card

    private var dailySummaryCard: some View {
        let totals = viewModel.dailyTotals(from: allMeals)
        let goal = viewModel.activeGoal(from: allGoals)

        return VStack(spacing: 16) {
            // Calorie headline
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(String(format: "%.0f", totals.calories))
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                Text("kcal")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Spacer()
                if let goal {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Objetivo")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(goal.caloriesTarget) kcal")
                            .font(.subheadline.weight(.semibold))
                        let remaining = Double(goal.caloriesTarget) - totals.calories
                        Text(remaining >= 0
                            ? "\(String(format: "%.0f", remaining)) restantes"
                            : "\(String(format: "%.0f", -remaining)) excedidas")
                        .font(.caption)
                        .foregroundStyle(remaining >= 0 ? .secondary : .red)
                    }
                }
            }

            // Macro progress bars
            VStack(spacing: 10) {
                MacroBar(
                    label: "Proteína",
                    current: totals.protein,
                    target: goal.map { Double($0.proteinG) },
                    unit: "g",
                    color: .blue
                )
                MacroBar(
                    label: "Carbos",
                    current: totals.carbs,
                    target: goal.map { Double($0.carbsG) },
                    unit: "g",
                    color: .orange
                )
                MacroBar(
                    label: "Grasas",
                    current: totals.fat,
                    target: goal.map { Double($0.fatG) },
                    unit: "g",
                    color: .yellow
                )
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Meal sections

    private var mealSections: some View {
        VStack(spacing: 12) {
            ForEach(MealType.allCases, id: \.self) { mealType in
                let meal = viewModel.meal(type: mealType, from: allMeals)
                MealSectionCard(
                    mealType: mealType,
                    meal: meal,
                    onAdd: { addingToMealType = mealType },
                    onDeleteEntry: { entry in
                        viewModel.deleteEntry(entry, modelContext: modelContext)
                    }
                )
            }
        }
    }
}

// MARK: - MealType Identifiable extension (para sheet binding)

extension MealType: Identifiable {
    public var id: String { rawValue }
}

// MARK: - MealSectionCard

private struct MealSectionCard: View {

    let mealType: MealType
    let meal: MealLog?
    let onAdd: () -> Void
    let onDeleteEntry: (MealFoodEntry) -> Void

    @State private var isExpanded = true

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: mealType.systemImage)
                        .foregroundStyle(.orange)
                        .frame(width: 24)
                    Text(mealType.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Spacer()
                    if let meal, meal.totalCalories > 0 {
                        Text(String(format: "%.0f kcal", meal.totalCalories))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider().padding(.horizontal, 14)

                // Food entries
                if let meal, !meal.entries.isEmpty {
                    ForEach(meal.entries) { entry in
                        EntryRow(entry: entry)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    onDeleteEntry(entry)
                                } label: {
                                    Label("Eliminar", systemImage: "trash")
                                }
                            }
                        Divider().padding(.leading, 14)
                    }
                }

                // Add button
                Button {
                    onAdd()
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.blue)
                        Text("Añadir alimento")
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - EntryRow

private struct EntryRow: View {
    let entry: MealFoodEntry

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.foodItem?.name ?? "Alimento desconocido")
                    .font(.subheadline)
                    .lineLimit(1)
                Text(String(format: "%.0f g", entry.quantityG))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.0f kcal", entry.calories))
                    .font(.subheadline.weight(.semibold))
                Text("P:\(String(format: "%.0f", entry.proteinG)) C:\(String(format: "%.0f", entry.carbsG)) G:\(String(format: "%.0f", entry.fatG))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - MacroBar

private struct MacroBar: View {
    let label: String
    let current: Double
    let target: Double?
    let unit: String
    let color: Color

    private var progress: Double {
        guard let target, target > 0 else { return 0 }
        return min(current / target, 1.0)
    }

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(String(format: "%.0f", current))
                    .font(.caption.weight(.semibold))
                if let target {
                    Text("/ \(String(format: "%.0f", target)) \(unit)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text(unit)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(.systemGray5)).frame(height: 6)
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * progress, height: 6)
                }
            }
            .frame(height: 6)
        }
    }
}
