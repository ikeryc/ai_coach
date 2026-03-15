import SwiftUI
import SwiftData

struct AIGenerationSheet: View {

    let goal: TrainingGoal
    let daysPerWeek: Int
    let totalWeeks: Int
    let profile: UserProfile?
    let onCreated: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var exercises: [Exercise]

    @State private var state: GenerationState = .idle
    @State private var explanation = ""
    @State private var errorMessage: String?

    enum GenerationState {
        case idle, loading, done, error
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    contextPreviewSection
                    switch state {
                    case .idle:
                        generateButton
                    case .loading:
                        loadingSection
                    case .done:
                        successSection
                    case .error:
                        errorSection
                    }
                }
                .padding()
            }
            .navigationTitle("Generar con IA")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
    }

    // MARK: - Context preview

    private var contextPreviewSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.purple)
                Text("Contexto para Claude")
                    .font(.headline)
            }

            contextRow(icon: "target", label: "Objetivo", value: goal.displayName)
            contextRow(icon: "calendar", label: "Días/semana", value: "\(daysPerWeek) días")
            contextRow(icon: "clock", label: "Duración", value: "\(totalWeeks) semanas")
            if let profile {
                contextRow(icon: "person.fill", label: "Experiencia", value: profile.experienceLevel.displayName)
                contextRow(icon: "dumbbell.fill", label: "Equipamiento", value: profile.equipment.displayName)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func contextRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 20)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
        }
    }

    // MARK: - States

    private var generateButton: some View {
        Button {
            Task { await generate() }
        } label: {
            Label("Generar programa", systemImage: "sparkles")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .tint(.purple)
    }

    private var loadingSection: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Claude está diseñando tu programa...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Esto puede tardar unos segundos")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 40)
    }

    private var successSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.green)
            Text("Programa creado")
                .font(.title3.bold())
            if !explanation.isEmpty {
                Text(explanation)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            Button("Ver programa") {
                onCreated()
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.vertical, 20)
    }

    private var errorSection: some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.orange)
            Text("Error al generar")
                .font(.headline)
            if let msg = errorMessage {
                Text(msg)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Button("Reintentar") {
                Task { await generate() }
            }
            .buttonStyle(.bordered)
        }
        .padding(.vertical, 20)
    }

    // MARK: - Generation

    private func generate() async {
        guard let profile else {
            errorMessage = "No se encontró el perfil de usuario."
            state = .error
            return
        }

        state = .loading

        let context = ProgramGenerationContext(
            goal: goal.rawValue,
            experienceLevel: profile.experienceLevel.rawValue,
            availableDays: daysPerWeek,
            equipment: profile.equipment.rawValue
        )

        guard let contextData = try? JSONEncoder().encode(context),
              let contextJSON = String(data: contextData, encoding: .utf8) else {
            errorMessage = "Error preparando el contexto."
            state = .error
            return
        }

        let request = ProgramGenerationRequest(
            userId: profile.supabaseUserId,
            contextJSON: contextJSON
        )

        do {
            let response: ProgramGenerationResponse = try await EdgeFunctionClient.shared.generateTrainingProgram(context: request)
            explanation = response.explanation

            // Parse and save the program
            try createProgram(from: response.programJSON, goal: goal, totalWeeks: totalWeeks, profile: profile)
            state = .done
        } catch {
            errorMessage = error.localizedDescription
            state = .error
        }
    }

    // MARK: - Program creation from JSON

    private func createProgram(
        from json: String,
        goal: TrainingGoal,
        totalWeeks: Int,
        profile: UserProfile
    ) throws {
        guard let data = json.data(using: .utf8) else {
            throw AppError.decodingFailed
        }
        let dto = try JSONDecoder().decode(GeneratedProgramDTO.self, from: data)

        let program = TrainingProgram(
            name: dto.name,
            goal: goal,
            totalWeeks: dto.totalWeeks,
            status: .draft,
            aiGenerated: true
        )
        program.userProfile = profile
        modelContext.insert(program)

        ProgramFactory.buildMesocycles(for: program, weeks: dto.totalWeeks, modelContext: modelContext)

        for week in 1...dto.totalWeeks {
            let isDeload = week == dto.totalWeeks
            for day in dto.days {
                let template = WorkoutTemplate(
                    weekNumber: week,
                    dayOfWeek: day.dayOfWeek,
                    name: day.name + (isDeload ? " (Descarga)" : ""),
                    estimatedDurationMinutes: day.exercises.count * 12,
                    isDeload: isDeload
                )
                template.program = program
                modelContext.insert(template)

                for (idx, exDTO) in day.exercises.enumerated() {
                    let slot = ExerciseSlot(
                        orderIndex: idx,
                        setsCount: isDeload ? max(2, exDTO.sets - 1) : exDTO.sets,
                        repRangeMin: exDTO.repMin,
                        repRangeMax: exDTO.repMax,
                        rirTarget: isDeload ? exDTO.rir + 2 : exDTO.rir,
                        restSeconds: exDTO.restSeconds ?? 120
                    )
                    slot.workoutTemplate = template
                    // Match exercise by name (case-insensitive)
                    slot.exercise = exercises.first {
                        $0.name.lowercased() == exDTO.exerciseName.lowercased()
                    }
                    slot.notes = slot.exercise == nil ? exDTO.exerciseName : ""
                    modelContext.insert(slot)
                }
            }
        }

        try modelContext.save()
    }
}

private enum AppError: LocalizedError {
    case decodingFailed
    var errorDescription: String? { "No se pudo interpretar la respuesta de la IA." }
}
