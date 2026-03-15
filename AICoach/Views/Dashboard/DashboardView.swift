import SwiftUI
import SwiftData

struct DashboardView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(AppViewModel.self) private var appViewModel
    @Query private var profiles: [UserProfile]
    @Query(sort: \TrainingSession.date, order: .reverse) private var sessions: [TrainingSession]

    @State private var viewModel = DashboardViewModel()

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let profile {
                        greetingSection(profile: profile)
                        activeProgramCard(profile: profile)
                        weekStatsSection(profile: profile)
                        recentSessionsSection(profile: profile)
                    } else {
                        ContentUnavailableView("Sin perfil", systemImage: "person.fill")
                            .padding(.top, 80)
                    }
                }
                .padding(.horizontal)
                .padding(.top)
            }
            .navigationTitle("AI Coach")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if let p = profile {
                            viewModel.refresh(for: p, modelContext: modelContext)
                        }
                    } label: {
                        if viewModel.isRefreshing {
                            ProgressView().scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .disabled(viewModel.isRefreshing)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Sign Out") {
                        Task { await appViewModel.signOut(modelContext: modelContext) }
                    }
                    .foregroundStyle(.red)
                    .font(.subheadline)
                }
            }
            .task {
                if let p = profile {
                    viewModel.refresh(for: p, modelContext: modelContext)
                }
            }
        }
    }

    // MARK: - Greeting

    private func greetingSection(profile: UserProfile) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greetingText)
                    .font(.title2.bold())
                Text(Date.now.formatted(date: .complete, time: .omitted))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(profile.primaryGoal.displayName)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.blue.opacity(0.12))
                .foregroundStyle(.blue)
                .clipShape(Capsule())
        }
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "Buenos días"
        case 12..<19: return "Buenas tardes"
        default: return "Buenas noches"
        }
    }

    // MARK: - Active program

    private func activeProgramCard(profile: UserProfile) -> some View {
        Group {
            if let prog = viewModel.activeProgram(for: profile) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Label("Programa activo", systemImage: "figure.strengthtraining.traditional")
                            .font(.headline)
                        Spacer()
                        if let week = prog.currentWeek {
                            Text("Sem. \(week)/\(prog.totalWeeks)")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.15))
                                .foregroundStyle(.green)
                                .clipShape(Capsule())
                        }
                    }
                    Text(prog.name)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if let week = prog.currentWeek {
                        ProgressView(value: Double(week), total: Double(prog.totalWeeks))
                            .tint(.blue)
                    }
                }
                .padding(16)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                HStack(spacing: 14) {
                    Image(systemName: "dumbbell")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Sin programa activo")
                            .font(.subheadline.weight(.semibold))
                        Text("Ve a Entreno para crear o activar uno")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(16)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    // MARK: - Week stats

    private func weekStatsSection(profile: UserProfile) -> some View {
        let metrics = viewModel.currentWeekMetrics(for: profile)

        return VStack(alignment: .leading, spacing: 12) {
            Text("Esta semana")
                .font(.headline)

            HStack(spacing: 12) {
                DashStatCard(
                    title: "Sesiones",
                    value: "\(metrics?.trainingSessionsCompleted ?? 0)/\(metrics?.trainingSessionsPlanned ?? 0)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                DashStatCard(
                    title: "Peso medio",
                    value: metrics?.avgWeight7d.map { String(format: "%.1f kg", $0) } ?? "--",
                    icon: "scalemass.fill",
                    color: .blue
                )
                DashStatCard(
                    title: "Adherencia",
                    value: metrics?.avgCalorieAdherence.map { String(format: "%.0f%%", $0) } ?? "--",
                    icon: "fork.knife",
                    color: .orange
                )
            }

            if let metrics, let change = metrics.weightChangeVsPrevWeek {
                let sign = change >= 0 ? "+" : ""
                let color = weightChangeColor(change: change, goal: profile.primaryGoal)
                HStack(spacing: 4) {
                    Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .foregroundStyle(color)
                    Text("\(sign)\(String(format: "%.2f", change)) kg vs semana anterior")
                        .font(.caption)
                        .foregroundStyle(color)
                }
                .padding(.horizontal, 4)
            }
        }
    }

    private func weightChangeColor(change: Double, goal: TrainingGoal) -> Color {
        switch goal {
        case .hypertrophy, .strength: return change > 0 ? .green : .orange
        case .fatLoss: return change < 0 ? .green : .orange
        case .recomposition: return abs(change) < 0.2 ? .green : .orange
        }
    }

    // MARK: - Recent sessions

    @ViewBuilder
    private func recentSessionsSection(profile: UserProfile) -> some View {
        let recent = viewModel.recentSessions(for: profile)
        if !recent.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Últimas sesiones")
                    .font(.headline)

                ForEach(recent) { session in
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(session.workoutTemplate?.name ?? "Sesión libre")
                                .font(.subheadline.weight(.semibold))
                            Text(session.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 3) {
                            Text(String(format: "%.0f kg", session.totalVolume))
                                .font(.subheadline.weight(.semibold))
                            Text(session.durationDisplay)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.bottom, 20)
        }
    }
}

// MARK: - DashStatCard

private struct DashStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(color)
            Text(value)
                .font(.subheadline.bold())
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
