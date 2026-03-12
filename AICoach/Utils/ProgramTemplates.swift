import Foundation
import SwiftData

// MARK: - Definición de Templates

struct ProgramTemplate: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let goal: TrainingGoal
    let experienceLevel: ExperienceLevel
    let daysPerWeek: Int
    let totalWeeks: Int
    let days: [TemplateDayDefinition]
    let splitName: String
}

struct TemplateDayDefinition {
    let dayOfWeek: Int          // 0=lunes
    let name: String
    let exercises: [TemplateExerciseDef]
}

struct TemplateExerciseDef {
    let name: String            // nombre exacto o aproximado en la biblioteca wger
    let muscle: MuscleGroup
    let sets: Int
    let repMin: Int
    let repMax: Int
    let rir: Int
    let restSeconds: Int
    let progression: ProgressionModel
}

// MARK: - Catálogo de Templates

enum ProgramTemplatesCatalog {

    static let all: [ProgramTemplate] = [ppl, upperLower, fullBody3x, gzclp]

    // MARK: PPL — Push Pull Legs ×2 (6 días)
    static let ppl = ProgramTemplate(
        name: "Push Pull Legs",
        description: "Split clásico de 6 días que entrena cada grupo muscular 2 veces por semana. Óptimo para hipertrofia en intermedios y avanzados.",
        goal: .hypertrophy,
        experienceLevel: .intermediate,
        daysPerWeek: 6,
        totalWeeks: 6,
        days: [
            TemplateDayDefinition(dayOfWeek: 0, name: "Push A", exercises: [
                TemplateExerciseDef(name: "Bench Press", muscle: .chest, sets: 4, repMin: 6, repMax: 10, rir: 2, restSeconds: 150, progression: .doubleProgression),
                TemplateExerciseDef(name: "Overhead Press", muscle: .shoulders, sets: 3, repMin: 8, repMax: 12, rir: 2, restSeconds: 120, progression: .doubleProgression),
                TemplateExerciseDef(name: "Incline Dumbbell Fly", muscle: .chest, sets: 3, repMin: 10, repMax: 15, rir: 2, restSeconds: 90, progression: .doubleProgression),
                TemplateExerciseDef(name: "Lateral Raise", muscle: .shoulders, sets: 4, repMin: 12, repMax: 20, rir: 1, restSeconds: 60, progression: .doubleProgression),
                TemplateExerciseDef(name: "Triceps Pushdown", muscle: .triceps, sets: 3, repMin: 10, repMax: 15, rir: 2, restSeconds: 75, progression: .doubleProgression),
            ]),
            TemplateDayDefinition(dayOfWeek: 1, name: "Pull A", exercises: [
                TemplateExerciseDef(name: "Pull-Up", muscle: .back, sets: 4, repMin: 5, repMax: 10, rir: 2, restSeconds: 150, progression: .doubleProgression),
                TemplateExerciseDef(name: "Barbell Row", muscle: .back, sets: 4, repMin: 6, repMax: 10, rir: 2, restSeconds: 150, progression: .doubleProgression),
                TemplateExerciseDef(name: "Face Pull", muscle: .traps, sets: 3, repMin: 15, repMax: 20, rir: 2, restSeconds: 60, progression: .doubleProgression),
                TemplateExerciseDef(name: "Dumbbell Curl", muscle: .biceps, sets: 3, repMin: 10, repMax: 15, rir: 2, restSeconds: 75, progression: .doubleProgression),
                TemplateExerciseDef(name: "Hammer Curl", muscle: .biceps, sets: 3, repMin: 10, repMax: 15, rir: 2, restSeconds: 75, progression: .doubleProgression),
            ]),
            TemplateDayDefinition(dayOfWeek: 2, name: "Legs A", exercises: [
                TemplateExerciseDef(name: "Squat", muscle: .quads, sets: 4, repMin: 6, repMax: 10, rir: 2, restSeconds: 180, progression: .doubleProgression),
                TemplateExerciseDef(name: "Romanian Deadlift", muscle: .hamstrings, sets: 3, repMin: 8, repMax: 12, rir: 2, restSeconds: 150, progression: .doubleProgression),
                TemplateExerciseDef(name: "Leg Press", muscle: .quads, sets: 3, repMin: 10, repMax: 15, rir: 2, restSeconds: 120, progression: .doubleProgression),
                TemplateExerciseDef(name: "Leg Curl", muscle: .hamstrings, sets: 3, repMin: 10, repMax: 15, rir: 2, restSeconds: 90, progression: .doubleProgression),
                TemplateExerciseDef(name: "Standing Calf Raise", muscle: .calves, sets: 4, repMin: 12, repMax: 20, rir: 1, restSeconds: 60, progression: .doubleProgression),
            ]),
            TemplateDayDefinition(dayOfWeek: 3, name: "Push B", exercises: [
                TemplateExerciseDef(name: "Incline Bench Press", muscle: .chest, sets: 4, repMin: 8, repMax: 12, rir: 2, restSeconds: 120, progression: .doubleProgression),
                TemplateExerciseDef(name: "Dumbbell Shoulder Press", muscle: .shoulders, sets: 3, repMin: 10, repMax: 15, rir: 2, restSeconds: 90, progression: .doubleProgression),
                TemplateExerciseDef(name: "Cable Fly", muscle: .chest, sets: 3, repMin: 12, repMax: 15, rir: 2, restSeconds: 75, progression: .doubleProgression),
                TemplateExerciseDef(name: "Lateral Raise", muscle: .shoulders, sets: 4, repMin: 15, repMax: 20, rir: 1, restSeconds: 60, progression: .doubleProgression),
                TemplateExerciseDef(name: "Overhead Triceps Extension", muscle: .triceps, sets: 3, repMin: 10, repMax: 15, rir: 2, restSeconds: 75, progression: .doubleProgression),
            ]),
            TemplateDayDefinition(dayOfWeek: 4, name: "Pull B", exercises: [
                TemplateExerciseDef(name: "Lat Pulldown", muscle: .back, sets: 4, repMin: 8, repMax: 12, rir: 2, restSeconds: 120, progression: .doubleProgression),
                TemplateExerciseDef(name: "Seated Cable Row", muscle: .back, sets: 4, repMin: 8, repMax: 12, rir: 2, restSeconds: 120, progression: .doubleProgression),
                TemplateExerciseDef(name: "Rear Delt Fly", muscle: .shoulders, sets: 3, repMin: 15, repMax: 20, rir: 2, restSeconds: 60, progression: .doubleProgression),
                TemplateExerciseDef(name: "Barbell Curl", muscle: .biceps, sets: 3, repMin: 8, repMax: 12, rir: 2, restSeconds: 75, progression: .doubleProgression),
                TemplateExerciseDef(name: "Incline Dumbbell Curl", muscle: .biceps, sets: 3, repMin: 10, repMax: 15, rir: 2, restSeconds: 75, progression: .doubleProgression),
            ]),
            TemplateDayDefinition(dayOfWeek: 5, name: "Legs B", exercises: [
                TemplateExerciseDef(name: "Deadlift", muscle: .back, sets: 3, repMin: 4, repMax: 6, rir: 2, restSeconds: 210, progression: .doubleProgression),
                TemplateExerciseDef(name: "Hack Squat", muscle: .quads, sets: 3, repMin: 8, repMax: 12, rir: 2, restSeconds: 120, progression: .doubleProgression),
                TemplateExerciseDef(name: "Hip Thrust", muscle: .glutes, sets: 4, repMin: 10, repMax: 15, rir: 2, restSeconds: 90, progression: .doubleProgression),
                TemplateExerciseDef(name: "Leg Extension", muscle: .quads, sets: 3, repMin: 12, repMax: 15, rir: 2, restSeconds: 75, progression: .doubleProgression),
                TemplateExerciseDef(name: "Seated Calf Raise", muscle: .calves, sets: 4, repMin: 12, repMax: 20, rir: 1, restSeconds: 60, progression: .doubleProgression),
            ]),
        ],
        splitName: "PPL"
    )

    // MARK: Upper/Lower ×2 (4 días)
    static let upperLower = ProgramTemplate(
        name: "Upper / Lower",
        description: "4 días semanales con frecuencia 2 por grupo muscular. Excelente balance entre volumen y recuperación. Ideal para intermedios.",
        goal: .hypertrophy,
        experienceLevel: .intermediate,
        daysPerWeek: 4,
        totalWeeks: 8,
        days: [
            TemplateDayDefinition(dayOfWeek: 0, name: "Upper A", exercises: [
                TemplateExerciseDef(name: "Bench Press", muscle: .chest, sets: 4, repMin: 6, repMax: 10, rir: 2, restSeconds: 150, progression: .doubleProgression),
                TemplateExerciseDef(name: "Barbell Row", muscle: .back, sets: 4, repMin: 6, repMax: 10, rir: 2, restSeconds: 150, progression: .doubleProgression),
                TemplateExerciseDef(name: "Overhead Press", muscle: .shoulders, sets: 3, repMin: 8, repMax: 12, rir: 2, restSeconds: 120, progression: .doubleProgression),
                TemplateExerciseDef(name: "Lat Pulldown", muscle: .back, sets: 3, repMin: 8, repMax: 12, rir: 2, restSeconds: 90, progression: .doubleProgression),
                TemplateExerciseDef(name: "Triceps Pushdown", muscle: .triceps, sets: 3, repMin: 10, repMax: 15, rir: 2, restSeconds: 75, progression: .doubleProgression),
                TemplateExerciseDef(name: "Dumbbell Curl", muscle: .biceps, sets: 3, repMin: 10, repMax: 15, rir: 2, restSeconds: 75, progression: .doubleProgression),
            ]),
            TemplateDayDefinition(dayOfWeek: 1, name: "Lower A", exercises: [
                TemplateExerciseDef(name: "Squat", muscle: .quads, sets: 4, repMin: 6, repMax: 10, rir: 2, restSeconds: 180, progression: .doubleProgression),
                TemplateExerciseDef(name: "Romanian Deadlift", muscle: .hamstrings, sets: 3, repMin: 8, repMax: 12, rir: 2, restSeconds: 150, progression: .doubleProgression),
                TemplateExerciseDef(name: "Leg Press", muscle: .quads, sets: 3, repMin: 10, repMax: 15, rir: 2, restSeconds: 120, progression: .doubleProgression),
                TemplateExerciseDef(name: "Leg Curl", muscle: .hamstrings, sets: 3, repMin: 10, repMax: 15, rir: 2, restSeconds: 90, progression: .doubleProgression),
                TemplateExerciseDef(name: "Standing Calf Raise", muscle: .calves, sets: 4, repMin: 15, repMax: 20, rir: 1, restSeconds: 60, progression: .doubleProgression),
            ]),
            TemplateDayDefinition(dayOfWeek: 3, name: "Upper B", exercises: [
                TemplateExerciseDef(name: "Incline Bench Press", muscle: .chest, sets: 4, repMin: 8, repMax: 12, rir: 2, restSeconds: 120, progression: .doubleProgression),
                TemplateExerciseDef(name: "Seated Cable Row", muscle: .back, sets: 4, repMin: 8, repMax: 12, rir: 2, restSeconds: 120, progression: .doubleProgression),
                TemplateExerciseDef(name: "Dumbbell Shoulder Press", muscle: .shoulders, sets: 3, repMin: 10, repMax: 15, rir: 2, restSeconds: 90, progression: .doubleProgression),
                TemplateExerciseDef(name: "Pull-Up", muscle: .back, sets: 3, repMin: 5, repMax: 10, rir: 2, restSeconds: 120, progression: .doubleProgression),
                TemplateExerciseDef(name: "Overhead Triceps Extension", muscle: .triceps, sets: 3, repMin: 10, repMax: 15, rir: 2, restSeconds: 75, progression: .doubleProgression),
                TemplateExerciseDef(name: "Hammer Curl", muscle: .biceps, sets: 3, repMin: 10, repMax: 15, rir: 2, restSeconds: 75, progression: .doubleProgression),
            ]),
            TemplateDayDefinition(dayOfWeek: 4, name: "Lower B", exercises: [
                TemplateExerciseDef(name: "Deadlift", muscle: .back, sets: 3, repMin: 4, repMax: 6, rir: 2, restSeconds: 210, progression: .doubleProgression),
                TemplateExerciseDef(name: "Hack Squat", muscle: .quads, sets: 3, repMin: 8, repMax: 12, rir: 2, restSeconds: 120, progression: .doubleProgression),
                TemplateExerciseDef(name: "Hip Thrust", muscle: .glutes, sets: 4, repMin: 10, repMax: 15, rir: 2, restSeconds: 90, progression: .doubleProgression),
                TemplateExerciseDef(name: "Leg Extension", muscle: .quads, sets: 3, repMin: 12, repMax: 15, rir: 2, restSeconds: 75, progression: .doubleProgression),
                TemplateExerciseDef(name: "Seated Calf Raise", muscle: .calves, sets: 4, repMin: 15, repMax: 20, rir: 1, restSeconds: 60, progression: .doubleProgression),
            ]),
        ],
        splitName: "Upper/Lower"
    )

    // MARK: Full Body 3×/semana (principiantes)
    static let fullBody3x = ProgramTemplate(
        name: "Full Body 3×",
        description: "Tres sesiones semanales de cuerpo completo. Alta frecuencia por grupo muscular, volumen controlado. Ideal para principiantes.",
        goal: .hypertrophy,
        experienceLevel: .beginner,
        daysPerWeek: 3,
        totalWeeks: 8,
        days: [
            TemplateDayDefinition(dayOfWeek: 0, name: "Full Body A", exercises: [
                TemplateExerciseDef(name: "Squat", muscle: .quads, sets: 3, repMin: 5, repMax: 8, rir: 3, restSeconds: 180, progression: .linear),
                TemplateExerciseDef(name: "Bench Press", muscle: .chest, sets: 3, repMin: 5, repMax: 8, rir: 3, restSeconds: 150, progression: .linear),
                TemplateExerciseDef(name: "Barbell Row", muscle: .back, sets: 3, repMin: 5, repMax: 8, rir: 3, restSeconds: 150, progression: .linear),
                TemplateExerciseDef(name: "Overhead Press", muscle: .shoulders, sets: 2, repMin: 8, repMax: 12, rir: 3, restSeconds: 90, progression: .doubleProgression),
                TemplateExerciseDef(name: "Dumbbell Curl", muscle: .biceps, sets: 2, repMin: 10, repMax: 15, rir: 2, restSeconds: 60, progression: .doubleProgression),
            ]),
            TemplateDayDefinition(dayOfWeek: 2, name: "Full Body B", exercises: [
                TemplateExerciseDef(name: "Deadlift", muscle: .back, sets: 3, repMin: 5, repMax: 5, rir: 3, restSeconds: 210, progression: .linear),
                TemplateExerciseDef(name: "Incline Bench Press", muscle: .chest, sets: 3, repMin: 8, repMax: 12, rir: 3, restSeconds: 120, progression: .doubleProgression),
                TemplateExerciseDef(name: "Lat Pulldown", muscle: .back, sets: 3, repMin: 8, repMax: 12, rir: 3, restSeconds: 120, progression: .doubleProgression),
                TemplateExerciseDef(name: "Leg Press", muscle: .quads, sets: 3, repMin: 10, repMax: 15, rir: 2, restSeconds: 90, progression: .doubleProgression),
                TemplateExerciseDef(name: "Triceps Pushdown", muscle: .triceps, sets: 2, repMin: 10, repMax: 15, rir: 2, restSeconds: 60, progression: .doubleProgression),
            ]),
            TemplateDayDefinition(dayOfWeek: 4, name: "Full Body C", exercises: [
                TemplateExerciseDef(name: "Squat", muscle: .quads, sets: 3, repMin: 5, repMax: 8, rir: 3, restSeconds: 180, progression: .linear),
                TemplateExerciseDef(name: "Bench Press", muscle: .chest, sets: 3, repMin: 5, repMax: 8, rir: 3, restSeconds: 150, progression: .linear),
                TemplateExerciseDef(name: "Barbell Row", muscle: .back, sets: 3, repMin: 5, repMax: 8, rir: 3, restSeconds: 150, progression: .linear),
                TemplateExerciseDef(name: "Romanian Deadlift", muscle: .hamstrings, sets: 2, repMin: 10, repMax: 12, rir: 3, restSeconds: 90, progression: .doubleProgression),
                TemplateExerciseDef(name: "Lateral Raise", muscle: .shoulders, sets: 2, repMin: 15, repMax: 20, rir: 2, restSeconds: 60, progression: .doubleProgression),
            ]),
        ],
        splitName: "Full Body"
    )

    // MARK: GZCLP — Fuerza para principiantes (3 días)
    static let gzclp = ProgramTemplate(
        name: "GZCLP",
        description: "Programa de fuerza lineal para principiantes. Tres días con los movimientos principales. Progresión de peso en cada sesión.",
        goal: .strength,
        experienceLevel: .beginner,
        daysPerWeek: 3,
        totalWeeks: 12,
        days: [
            TemplateDayDefinition(dayOfWeek: 0, name: "Día A", exercises: [
                TemplateExerciseDef(name: "Squat", muscle: .quads, sets: 5, repMin: 3, repMax: 3, rir: 3, restSeconds: 210, progression: .linear),
                TemplateExerciseDef(name: "Bench Press", muscle: .chest, sets: 5, repMin: 3, repMax: 3, rir: 3, restSeconds: 150, progression: .linear),
                TemplateExerciseDef(name: "Deadlift", muscle: .back, sets: 1, repMin: 5, repMax: 5, rir: 3, restSeconds: 240, progression: .linear),
                TemplateExerciseDef(name: "Overhead Press", muscle: .shoulders, sets: 3, repMin: 10, repMax: 10, rir: 3, restSeconds: 90, progression: .linear),
                TemplateExerciseDef(name: "Lat Pulldown", muscle: .back, sets: 3, repMin: 10, repMax: 10, rir: 3, restSeconds: 90, progression: .linear),
            ]),
            TemplateDayDefinition(dayOfWeek: 2, name: "Día B", exercises: [
                TemplateExerciseDef(name: "Overhead Press", muscle: .shoulders, sets: 5, repMin: 3, repMax: 3, rir: 3, restSeconds: 150, progression: .linear),
                TemplateExerciseDef(name: "Deadlift", muscle: .back, sets: 5, repMin: 3, repMax: 3, rir: 3, restSeconds: 240, progression: .linear),
                TemplateExerciseDef(name: "Squat", muscle: .quads, sets: 3, repMin: 10, repMax: 10, rir: 3, restSeconds: 120, progression: .linear),
                TemplateExerciseDef(name: "Bench Press", muscle: .chest, sets: 3, repMin: 10, repMax: 10, rir: 3, restSeconds: 90, progression: .linear),
                TemplateExerciseDef(name: "Barbell Row", muscle: .back, sets: 3, repMin: 10, repMax: 10, rir: 3, restSeconds: 90, progression: .linear),
            ]),
            TemplateDayDefinition(dayOfWeek: 4, name: "Día C", exercises: [
                TemplateExerciseDef(name: "Squat", muscle: .quads, sets: 5, repMin: 3, repMax: 3, rir: 3, restSeconds: 210, progression: .linear),
                TemplateExerciseDef(name: "Bench Press", muscle: .chest, sets: 5, repMin: 3, repMax: 3, rir: 3, restSeconds: 150, progression: .linear),
                TemplateExerciseDef(name: "Deadlift", muscle: .back, sets: 1, repMin: 5, repMax: 5, rir: 3, restSeconds: 240, progression: .linear),
                TemplateExerciseDef(name: "Overhead Press", muscle: .shoulders, sets: 3, repMin: 10, repMax: 10, rir: 3, restSeconds: 90, progression: .linear),
                TemplateExerciseDef(name: "Lat Pulldown", muscle: .back, sets: 3, repMin: 10, repMax: 10, rir: 3, restSeconds: 90, progression: .linear),
            ]),
        ],
        splitName: "Fuerza Lineal"
    )
}

// MARK: - Factory: convierte un template en modelos SwiftData

enum ProgramFactory {

    static func create(
        from template: ProgramTemplate,
        startDate: Date = .now,
        modelContext: ModelContext
    ) -> TrainingProgram {

        let program = TrainingProgram(
            name: template.name,
            goal: template.goal,
            totalWeeks: template.totalWeeks,
            startDate: startDate,
            endDate: Calendar.current.date(byAdding: .weekOfYear, value: template.totalWeeks, to: startDate),
            status: .active,
            aiGenerated: false
        )
        modelContext.insert(program)

        // Añadir mesociclos
        buildMesocycles(for: program, weeks: template.totalWeeks, modelContext: modelContext)

        // Buscar ejercicios existentes en la biblioteca por nombre (fuzzy)
        let exerciseMap = buildExerciseMap(modelContext: modelContext)

        // Crear workout templates para cada semana
        for week in 1...template.totalWeeks {
            let isDeloadWeek = (week == template.totalWeeks)
            for day in template.days {
                let workoutTemplate = WorkoutTemplate(
                    weekNumber: week,
                    dayOfWeek: day.dayOfWeek,
                    name: day.name + (isDeloadWeek ? " (Descarga)" : ""),
                    estimatedDurationMinutes: estimatedDuration(day.exercises.count),
                    isDeload: isDeloadWeek
                )
                workoutTemplate.program = program
                modelContext.insert(workoutTemplate)

                for (index, exDef) in day.exercises.enumerated() {
                    let slot = ExerciseSlot(
                        orderIndex: index,
                        setsCount: isDeloadWeek ? max(2, exDef.sets - 2) : exDef.sets,
                        repRangeMin: exDef.repMin,
                        repRangeMax: exDef.repMax,
                        rirTarget: isDeloadWeek ? exDef.rir + 2 : exDef.rir,
                        restSeconds: exDef.restSeconds,
                        progressionModel: exDef.progression
                    )
                    slot.workoutTemplate = workoutTemplate
                    slot.exercise = findExercise(name: exDef.name, muscle: exDef.muscle, in: exerciseMap)
                    modelContext.insert(slot)
                }
            }
        }

        try? modelContext.save()
        return program
    }

    static func buildMesocycles(for program: TrainingProgram, weeks: Int, modelContext: ModelContext) {
        if weeks >= 6 {
            let accum = Mesocycle(number: 1, weekStart: 1, weekEnd: weeks - 2, phase: .accumulation)
            accum.program = program
            modelContext.insert(accum)
            let intens = Mesocycle(number: 2, weekStart: weeks - 1, weekEnd: weeks - 1, phase: .intensification)
            intens.program = program
            modelContext.insert(intens)
            let deload = Mesocycle(number: 3, weekStart: weeks, weekEnd: weeks, phase: .deload)
            deload.program = program
            modelContext.insert(deload)
        } else {
            let accum = Mesocycle(number: 1, weekStart: 1, weekEnd: weeks - 1, phase: .accumulation)
            accum.program = program
            modelContext.insert(accum)
            let deload = Mesocycle(number: 2, weekStart: weeks, weekEnd: weeks, phase: .deload)
            deload.program = program
            modelContext.insert(deload)
        }
    }

    private static func buildExerciseMap(modelContext: ModelContext) -> [String: Exercise] {
        let descriptor = FetchDescriptor<Exercise>()
        let exercises = (try? modelContext.fetch(descriptor)) ?? []
        var map: [String: Exercise] = [:]
        for ex in exercises {
            map[ex.name.lowercased()] = ex
        }
        return map
    }

    private static func findExercise(name: String, muscle: MuscleGroup, in map: [String: Exercise]) -> Exercise? {
        // Búsqueda exacta
        if let exact = map[name.lowercased()] { return exact }
        // Búsqueda parcial
        let query = name.lowercased()
        return map.first { $0.key.contains(query) || query.contains($0.key) }?.value
    }

    private static func estimatedDuration(_ exerciseCount: Int) -> Int {
        // ~12 minutos por ejercicio (sets + descanso)
        exerciseCount * 12
    }
}
