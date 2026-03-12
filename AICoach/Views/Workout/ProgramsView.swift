import SwiftUI
import SwiftData

struct ProgramsView: View {

    @Query(sort: \TrainingProgram.createdAt, order: .reverse) private var programs: [TrainingProgram]
    @State private var viewModel = ProgramViewModel()
    @State private var showTemplates = false
    @State private var showBuilder = false

    @Environment(\.modelContext) private var modelContext

    var activeProgram: TrainingProgram? { programs.first { $0.status == .active } }

    var body: some View {
        NavigationStack {
            Group {
                if programs.isEmpty {
                    emptyState
                } else {
                    programList
                }
            }
            .navigationTitle("Programas")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showTemplates = true
                        } label: {
                            Label("Desde template", systemImage: "square.grid.2x2")
                        }
                        Button {
                            showBuilder = true
                        } label: {
                            Label("Crear manual", systemImage: "pencil")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showTemplates) {
                TemplateSelectionView()
            }
            .sheet(isPresented: $showBuilder) {
                ProgramBuilderView()
            }
        }
    }

    // MARK: - Lista

    private var programList: some View {
        List {
            if let active = activeProgram {
                Section("Activo") {
                    NavigationLink {
                        ProgramDetailView(program: active)
                    } label: {
                        ProgramRow(program: active, viewModel: viewModel)
                    }
                }
            }

            let others = programs.filter { $0.status != .active }
            if !others.isEmpty {
                Section("Otros programas") {
                    ForEach(others) { program in
                        NavigationLink {
                            ProgramDetailView(program: program)
                        } label: {
                            ProgramRow(program: program, viewModel: viewModel)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                viewModel.delete(program, modelContext: modelContext)
                            } label: {
                                Label("Eliminar", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            if program.status != .active {
                                Button {
                                    viewModel.activate(program, modelContext: modelContext)
                                } label: {
                                    Label("Activar", systemImage: "play.fill")
                                }
                                .tint(.green)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Estado vacío

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Sin programas", systemImage: "calendar.badge.plus")
        } description: {
            Text("Elige un template o crea tu propio programa de entrenamiento.")
        } actions: {
            Button("Elegir template") { showTemplates = true }
                .buttonStyle(.borderedProminent)
        }
    }
}

// MARK: - ProgramRow

struct ProgramRow: View {
    let program: TrainingProgram
    let viewModel: ProgramViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(program.name)
                    .font(.headline)
                Spacer()
                StatusBadge(status: program.status)
            }

            HStack(spacing: 12) {
                Label(program.goal.displayName, systemImage: "target")
                Label("\(program.totalWeeks) semanas", systemImage: "calendar")
                if program.status == .active, let week = program.currentWeek {
                    Label("Sem. \(week)", systemImage: "arrow.right")
                        .foregroundStyle(.blue)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if program.status == .active {
                let progress = Double(program.currentWeek ?? 1) / Double(program.totalWeeks)
                ProgressView(value: progress)
                    .tint(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}

struct StatusBadge: View {
    let status: ProgramStatus

    var color: Color {
        switch status {
        case .active: .green
        case .draft: .secondary
        case .completed: .blue
        case .paused: .orange
        }
    }

    var body: some View {
        Text(status.displayName)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}
