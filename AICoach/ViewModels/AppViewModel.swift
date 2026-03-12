import Foundation
import SwiftData
import Observation

/// Gestiona el estado global de la app: autenticación y onboarding.
@Observable
final class AppViewModel {

    enum AppState {
        case loading
        case unauthenticated
        case onboarding              // autenticado pero sin perfil completo
        case ready                   // autenticado + perfil completo
    }

    var state: AppState = .loading
    var supabase: SupabaseService

    init(supabase: SupabaseService = .shared) {
        self.supabase = supabase
    }

    /// Llama al arrancar la app para restaurar sesión y determinar flujo inicial.
    func initialize(modelContext: ModelContext) async {
        await supabase.restoreSessionIfNeeded()

        if !supabase.isAuthenticated {
            await MainActor.run { state = .unauthenticated }
            return
        }

        let hasProfile = hasCompletedProfile(modelContext: modelContext)
        await MainActor.run {
            state = hasProfile ? .ready : .onboarding
        }
    }

    func onAuthSuccess(modelContext: ModelContext) {
        let hasProfile = hasCompletedProfile(modelContext: modelContext)
        state = hasProfile ? .ready : .onboarding
    }

    func onOnboardingComplete() {
        state = .ready
    }

    func signOut(modelContext: ModelContext) async {
        try? await supabase.signOut()
        state = .unauthenticated
    }

    private func hasCompletedProfile(modelContext: ModelContext) -> Bool {
        let descriptor = FetchDescriptor<UserProfile>()
        let profiles = (try? modelContext.fetch(descriptor)) ?? []
        return !profiles.isEmpty
    }
}
