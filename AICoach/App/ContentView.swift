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
    @Environment(AppViewModel.self) private var appViewModel
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Dashboard",
                systemImage: "house.fill",
                description: Text("Disponible en Fase 2")
            )
            .navigationTitle("AI Coach")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Sign Out") {
                        Task { await appViewModel.signOut(modelContext: modelContext) }
                    }
                    .foregroundStyle(.red)
                }
            }
        }
    }
}

struct WorkoutPlaceholderView: View {
    var body: some View {
        WorkoutHubView()
    }
}

struct NutritionPlaceholderView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Nutrición",
                systemImage: "fork.knife",
                description: Text("Disponible en Fase 7")
            )
            .navigationTitle("Nutrición")
        }
    }
}

struct ProgressPlaceholderView: View {
    var body: some View {
        BodyWeightView()
    }
}

struct ChatPlaceholderView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Entrenador IA",
                systemImage: "bubble.left.and.bubble.right.fill",
                description: Text("Disponible en Fase 8")
            )
            .navigationTitle("Entrenador")
        }
    }
}
