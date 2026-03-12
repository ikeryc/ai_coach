import SwiftUI
import SwiftData

struct ProgramDetailView: View {

    let program: TrainingProgram
    @State private var viewModel = ProgramViewModel()
    @State private var selectedWeek: Int = 1
    @State private var showDeleteAlert = false

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // Info general
                programInfoSection

                // Mesociclos
                if !program.mesocycles.isEmpty {
                    mesocycleSection
                }

                // Vista semanal
                weeklyPlanSection
            }
            .padding(.horizontal)
            .padding(.top)
            .padding(.bottom, 32)
        }
        .navigationTitle(program.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if program.status != .active {
                        Button {
                            viewModel.activate(program, modelContext: modelContext)
                        } label: {
                            Label("Activar programa", systemImage: "play.fill")
                        }
                    } else {
                        Button {
                            viewModel.pause(program, modelContext: modelContext)
                        } label: {
                            Label("Pausar programa", systemImage: "pause.fill")
                        }
                    }
                    Divider()
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Label("Eliminar", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("Eliminar programa", isPresented: $showDeleteAlert) {
            Button("Eliminar", role: .destructive) {
                viewModel.delete(program, modelContext: modelContext)
                dismiss()
            }
            Button("Cancelar", role: .cancel) {}
        }
    }

    // MARK: - Info general

    private var programInfoSection: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                InfoPill(icon: "target", label: program.goal.displayName, color: .blue)
                InfoPill(icon: "calendar", label: "\(program.totalWeeks) semanas", color: .orange)
                InfoPill(icon: "figure.strengthtraining.traditional", label: "\(program.workoutTemplates.filter { $0.weekNumber == 1 }.count) días/sem", color: .purple)
            }
            if program.status == .active, let week = program.currentWeek {
                HStack {
                    Text("Semana actual: \(week) / \(program.totalWeeks)")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    StatusBadge(status: program.status)
                }
            } else {
                HStack {
                    Spacer()
                    StatusBadge(status: program.status)
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Mesociclos

    private var mesocycleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Estructura")
                .font(.headline)

            HStack(spacing: 8) {
                ForEach(program.mesocycles.sorted { $0.number < $1.number }) { meso in
                    VStack(spacing: 4) {
                        Text(meso.phase.displayName)
                            .font(.caption.weight(.semibold))
                        Text("S\(meso.weekStart)–S\(meso.weekEnd)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(phaseColor(meso.phase).opacity(0.1))
                    .foregroundStyle(phaseColor(meso.phase))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }

    private func phaseColor(_ phase: MesocyclePhase) -> Color {
        switch phase {
        case .accumulation: .blue
        case .intensification: .orange
        case .deload: .green
        }
    }

    // MARK: - Plan semanal

    private var weeklyPlanSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Plan semanal")
                    .font(.headline)
                Spacer()
                // Selector de semana compacto
                Picker("Semana", selection: $selectedWeek) {
                    ForEach(1...program.totalWeeks, id: \.self) { w in
                        Text("Sem. \(w)").tag(w)
                    }
                }
                .pickerStyle(.menu)
            }

            let days = program.workoutTemplates
                .filter { $0.weekNumber == selectedWeek }
                .sorted { $0.dayOfWeek < $1.dayOfWeek }

            ForEach(days) { template in
                WorkoutTemplateCard(template: template)
            }

            if days.isEmpty {
                Text("Sin sesiones planificadas")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - WorkoutTemplateCard

struct WorkoutTemplateCard: View {
    let template: WorkoutTemplate
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(template.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text("\(template.dayName) · \(template.sortedSlots.count) ejercicios · ~\(template.estimatedDurationMinutes) min")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if template.isDeload {
                        Text("Descarga").font(.caption2)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.orange.opacity(0.15)).foregroundStyle(.orange)
                            .clipShape(Capsule())
                    }
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(14)
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider().padding(.horizontal)

                VStack(spacing: 0) {
                    // Cabecera
                    HStack {
                        Text("Ejercicio").frame(maxWidth: .infinity, alignment: .leading)
                        Text("Series").frame(width: 48, alignment: .center)
                        Text("Reps").frame(width: 60, alignment: .center)
                        Text("RIR").frame(width: 36, alignment: .center)
                    }
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)

                    ForEach(template.sortedSlots) { slot in
                        HStack {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(slot.exercise?.name ?? "Sin ejercicio")
                                    .font(.subheadline)
                                    .foregroundStyle(slot.exercise == nil ? .secondary : .primary)
                                if let muscle = slot.exercise?.primaryMuscleGroup {
                                    Text(muscle.displayName)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            Text("\(slot.setsCount)").frame(width: 48, alignment: .center)
                            Text("\(slot.repRangeMin)–\(slot.repRangeMax)").frame(width: 60, alignment: .center)
                            Text("\(slot.rirTarget)").frame(width: 36, alignment: .center)
                        }
                        .font(.subheadline)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)

                        if slot.id != template.sortedSlots.last?.id {
                            Divider().padding(.leading, 14)
                        }
                    }
                }
                .padding(.bottom, 8)
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct InfoPill: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        Label(label, systemImage: icon)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.1))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}
