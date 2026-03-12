import SwiftUI
import SwiftData

@main
struct AICoachApp: App {

    let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(
                for:
                    UserProfile.self,
                    Exercise.self,
                    TrainingProgram.self,
                    Mesocycle.self,
                    WorkoutTemplate.self,
                    ExerciseSlot.self,
                    TrainingSession.self,
                    ExerciseSet.self,
                    BodyWeightLog.self,
                    FoodItem.self,
                    MealLog.self,
                    MealFoodEntry.self,
                    NutritionGoal.self,
                    NutritionLog.self,
                    WeeklyMetrics.self,
                    AdaptationEvent.self,
                    AIConversation.self,
                    AIMessage.self
            )
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
                .task {
                    // Seed de ejercicios en background al primer arranque
                    let context = ModelContext(modelContainer)
                    await WgerService.shared.seedIfNeeded(modelContext: context)
                }
        }
    }
}
