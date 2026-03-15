import SwiftUI
import SwiftData

struct ContentView: View {

    @Environment(\.modelContext) private var modelContext
    @State private var appViewModel = AppViewModel()

    var body: some View {
        Group {
            switch appViewModel.state {
            case .loading:
                LoadingView()

            case .unauthenticated:
                AuthView {
                    appViewModel.onAuthSuccess(modelContext: modelContext)
                }

            case .onboarding:
                OnboardingCoordinatorView {
                    appViewModel.onOnboardingComplete()
                }

            case .ready:
                MainTabView()
            }
        }
        .task {
            await appViewModel.initialize(modelContext: modelContext)
        }
        .environment(appViewModel)
    }
}

// MARK: - Main Tab View

struct MainTabView: View {

    @State private var selectedTab: AppTab = .dashboard
    @Query(
        filter: #Predicate<AdaptationEvent> { !$0.userApproved },
        sort: \AdaptationEvent.appliedAt, order: .reverse
    ) private var pendingAdaptations: [AdaptationEvent]

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Dashboard", systemImage: "house.fill", value: AppTab.dashboard) {
                DashboardPlaceholderView()
            }
            Tab("Entreno", systemImage: "dumbbell.fill", value: AppTab.workout) {
                WorkoutPlaceholderView()
            }
            Tab("Nutrición", systemImage: "fork.knife", value: AppTab.nutrition) {
                NutritionPlaceholderView()
            }
            Tab("Progreso", systemImage: "chart.line.uptrend.xyaxis", value: AppTab.progress) {
                ProgressPlaceholderView()
            }
            Tab("Entrenador", systemImage: "bubble.left.and.bubble.right.fill", value: AppTab.chat) {
                ChatPlaceholderView()
            }
            .badge(pendingAdaptations.isEmpty ? 0 : pendingAdaptations.count)
        }
        .tint(.blue)
    }
}

enum AppTab: String, Hashable {
    case dashboard
    case workout
    case nutrition
    case progress
    case chat
}

// MARK: - Loading View

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 56))
                .foregroundStyle(.blue)
            ProgressView()
        }
    }
}

// MARK: - Placeholder Views (se reemplazan en fases siguientes)

struct DashboardPlaceholderView: View {
    var body: some View {
        DashboardView()
    }
}

struct WorkoutPlaceholderView: View {
    var body: some View {
        WorkoutHubView()
    }
}

struct NutritionPlaceholderView: View {
    var body: some View {
        NutritionView()
    }
}

struct ProgressPlaceholderView: View {
    var body: some View {
        ProgressHubView()
    }
}

struct ChatPlaceholderView: View {
    var body: some View {
        CoachView()
    }
}
