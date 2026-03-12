import SwiftUI
import SwiftData

struct WorkoutHubView: View {

    @Query(sort: \TrainingSession.date, order: .reverse) private var sessions: [TrainingSession]
    @Query(sort: \TrainingProgram.createdAt, order: .reverse) private var programs: [TrainingProgram]
    @Query private var profiles: [UserProfile]

    @State private var sessionViewModel = WorkoutSessionViewModel()
    @State private var programViewModel = ProgramViewModel()
    @State private var showActiveWorkout = false
    @State private var pendingTemplate: WorkoutTemplate?

    @Environment(\.modelContext) private var modelContext

    private var userProfile: UserProfile? { profiles.first }
    private var activeProgram: TrainingProgram? { programs.first { $0.status == .active } }
    private var recentSessions: [TrainingSession] { Array(sessions.prefix(5)) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Programa activo (si existe)
                    if let program = activeProgram {
                        ActiveProgramView(program: program) { template in
                            startWorkout(from: template)
                        }
                    }

                    // Botones de inicio
                    startButtons

                    // Sesiones recientes
                    if !sessions.isEmpty {
                        recentSessionsSection
                    }
                }
                .padding(.horizontal)
                .padding(.top)
            }
            .navigationTitle("Entrenamiento")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink {
                        ProgramsView()
                    } label: {
                        Image(systemName: "calendar.badge.plus")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        WorkoutHistoryView()
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                }
            }
            .fullScreenCover(isPresented: $showActiveWorkout) {
                ActiveWorkoutView(viewModel: sessionViewModel, userProfile: userProfile) {
                    showActiveWorkout = false
                    sessionViewModel = WorkoutSessionViewModel()
                }
            }
        }
    }

    // MARK: - Botones de inicio

    private var startButtons: some View {
        VStack(spacing: 10) {
            Button {
                startWorkout(from: nil)
            } label: {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Sesión libre")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            HStack(spacing: 8) {
                StatPill(
                    value: "\(sessions.filter { Calendar.current.isDateInThisWeek($0.date) }.count)",
                    label: "esta semana"
                )
                StatPill(
                    value: "\(sessions.count)",
                    label: "sesiones total"
                )
                if let last = sessions.first?.date {
                    StatPill(
                        value: Calendar.current.isDateInToday(last) ? "hoy" : last.formatted(.relative(presentation: .named)),
                        label: "último entreno"
                    )
                }
            }
        }
    }

    // MARK: - Sesiones recientes

    private var recentSessionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recientes")
                .font(.headline)

            ForEach(recentSessions) { session in
                NavigationLink {
                    WorkoutDetailView(session: session)
                } label: {
                    SessionCard(session: session)
                }
                .buttonStyle(.plain)
            }

            if sessions.count > 5 {
                NavigationLink("Ver todo el historial →") {
                    WorkoutHistoryView()
                }
                .font(.subheadline)
                .foregroundStyle(.blue)
            }
        }
    }

    // MARK: - Iniciar sesión

    private func startWorkout(from template: WorkoutTemplate?) {
        let name = template?.name ?? "Sesión libre"
        sessionViewModel.startSession(name: name, modelContext: modelContext, userProfile: userProfile)
        sessionViewModel.requestNotificationPermission()

        // Pre-cargar ejercicios del template
        if let template {
            for slot in template.sortedSlots {
                if let exercise = slot.exercise {
                    sessionViewModel.addExercise(exercise, modelContext: modelContext)
                }
            }
        }

        showActiveWorkout = true
    }
}

// MARK: - Subviews reutilizables

private struct StatPill: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline.bold())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

extension Calendar {
    func isDateInThisWeek(_ date: Date) -> Bool {
        isDate(date, equalTo: .now, toGranularity: .weekOfYear)
    }
}
