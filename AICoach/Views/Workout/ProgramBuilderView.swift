import SwiftUI
import SwiftData

struct ProgramBuilderView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]

    // Paso 1: info general
    @State private var name = ""
    @State private var goal: TrainingGoal = .hypertrophy
    @State private var totalWeeks = 6
    @State private var daysPerWeek = 4

    // Paso 2: días
    @State private var workoutDays: [BuilderDay] = []
    @State private var currentStep = 1
    @State private var showExercisePicker = false
    @State private var editingDayIndex: Int?

    // IA
    @State private var showAIGeneration = false

    struct BuilderDay: Identifiable {
        let id = UUID()
        var dayOfWeek: Int
        var name: String
        var exercises: [BuilderExercise]
    }

    struct BuilderExercise: Identifiable {
        let id = UUID()
        var exercise: Exercise
        var sets = 3
        var repMin = 8
        var repMax = 12
        var rir = 2
        var restSeconds = 120
    }

    var canProceed: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }
    var canSave: Bool { !workoutDays.isEmpty && workoutDays.allSatisfy { !$0.exercises.isEmpty } }

    var body: some View {
        NavigationStack {
            Group {
                if currentStep == 1 {
                    step1
                } else {
                    step2
                }
            }
            .navigationTitle(currentStep == 1 ? "Nuevo programa" : "Días de entreno")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(currentStep == 1 ? "Cancelar" : "Atrás") {
                        if currentStep == 1 { dismiss() } else { currentStep = 1 }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if currentStep == 1 {
                        Button("Siguiente") { setupDays(); currentStep = 2 }
                            .fontWeight(.semibold)
                            .disabled(!canProceed)
                    } else {
                        Button("Guardar") { saveProgram() }
                            .fontWeight(.semibold)
                            .disabled(!canSave)
                    }
                }
            }
            .sheet(isPresented: $showExercisePicker) {
                if let idx = editingDayIndex {
                    ExercisePickerView { exercise in
                        workoutDays[idx].exercises.append(
                            BuilderExercise(exercise: exercise)
                        )
                    }
                }
            }
            .sheet(isPresented: $showAIGeneration) {
                AIGenerationSheet(
                    goal: goal,
                    daysPerWeek: daysPerWeek,
                    totalWeeks: totalWeeks,
                    profile: profiles.first,
                    onCreated: { dismiss() }
                )
            }
        }
    }

    // MARK: - Paso 1: Info general

    private var step1: some View {
        Form {
            Section("Nombre del programa") {
                TextField("Ej: Mi PPL verano", text: $name)
            }

            Section("Objetivo") {
                Picker("Objetivo", selection: $goal) {
                    ForEach(TrainingGoal.allCases, id: \.self) { g in
                        Text(g.displayName).tag(g)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            }

            Section("Duración") {
                Stepper("\(totalWeeks) semanas", value: $totalWeeks, in: 2...16)
            }

            Section("Días por semana") {
                Stepper("\(daysPerWeek) días", value: $daysPerWeek, in: 2...6)
            }

            Section {
                Button {
                    showAIGeneration = true
                } label: {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundStyle(.purple)
                        Text("Generar con IA")
                            .foregroundStyle(.purple)
                            .fontWeight(.semibold)
                        Spacer()
                        Text("Claude Opus")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } footer: {
                Text("Claude generará un programa personalizado basado en tu perfil y objetivos.")
            }
        }
    }

    // MARK: - Paso 2: Días de entreno

    private var step2: some View {
        List {
            ForEach($workoutDays) { $day in
                Section(day.dayName + " — " + day.name) {
                    TextField("Nombre del día", text: $day.name)

                    ForEach($day.exercises) { $ex in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(ex.exercise.name)
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                Button(role: .destructive) {
                                    day.exercises.removeAll { $0.id == ex.id }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.plain)
                            }
                            HStack(spacing: 12) {
                                Stepper("\(ex.sets) sets", value: $ex.sets, in: 1...8)
                                    .fixedSize()
                                Text("\(ex.repMin)–\(ex.repMax)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .font(.caption)
                        }
                    }

                    Button {
                        editingDayIndex = workoutDays.firstIndex { $0.id == day.id }
                        showExercisePicker = true
                    } label: {
                        Label("Añadir ejercicio", systemImage: "plus.circle")
                            .font(.subheadline)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Helpers

    private func setupDays() {
        guard workoutDays.isEmpty else { return }
        let defaultDays = defaultDayAssignment(count: daysPerWeek)
        workoutDays = defaultDays.enumerated().map { idx, dayOfWeek in
            BuilderDay(
                dayOfWeek: dayOfWeek,
                name: "Día \(idx + 1)",
                exercises: []
            )
        }
    }

    private func defaultDayAssignment(count: Int) -> [Int] {
        switch count {
        case 2: return [0, 3]           // Lun, Jue
        case 3: return [0, 2, 4]        // Lun, Mié, Vie
        case 4: return [0, 1, 3, 4]     // Lun, Mar, Jue, Vie
        case 5: return [0, 1, 2, 3, 4]  // Lun–Vie
        case 6: return [0, 1, 2, 3, 4, 5]
        default: return Array(0..<count)
        }
    }

    private func saveProgram() {
        let program = TrainingProgram(
            name: name.trimmingCharacters(in: .whitespaces),
            goal: goal,
            totalWeeks: totalWeeks,
            status: .draft,
            aiGenerated: false
        )
        modelContext.insert(program)

        // Mesociclos
        ProgramFactory.buildMesocycles(for: program, weeks: totalWeeks, modelContext: modelContext)

        for week in 1...totalWeeks {
            let isDeload = week == totalWeeks
            for day in workoutDays {
                let template = WorkoutTemplate(
                    weekNumber: week,
                    dayOfWeek: day.dayOfWeek,
                    name: day.name + (isDeload ? " (Descarga)" : ""),
                    estimatedDurationMinutes: day.exercises.count * 12,
                    isDeload: isDeload
                )
                template.program = program
                modelContext.insert(template)

                for (idx, ex) in day.exercises.enumerated() {
                    let slot = ExerciseSlot(
                        orderIndex: idx,
                        setsCount: isDeload ? max(2, ex.sets - 1) : ex.sets,
                        repRangeMin: ex.repMin,
                        repRangeMax: ex.repMax,
                        rirTarget: isDeload ? ex.rir + 2 : ex.rir,
                        restSeconds: ex.restSeconds
                    )
                    slot.workoutTemplate = template
                    slot.exercise = ex.exercise
                    modelContext.insert(slot)
                }
            }
        }

        try? modelContext.save()
        dismiss()
    }
}

extension BuilderDay {
    var dayName: String {
        let days = ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"]
        guard dayOfWeek >= 0 && dayOfWeek < days.count else { return "Día" }
        return days[dayOfWeek]
    }
}

