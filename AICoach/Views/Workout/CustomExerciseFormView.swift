import SwiftUI
import SwiftData
import PhotosUI

struct CustomExerciseFormView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var primaryMuscle: MuscleGroup = .chest
    @State private var secondaryMuscles: Set<MuscleGroup> = []
    @State private var exerciseType: ExerciseType = .compound
    @State private var equipment: Equipment = .fullGym
    @State private var instructions = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var gifURL: String?

    @State private var isSaving = false

    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Información básica") {
                    TextField("Nombre del ejercicio", text: $name)

                    Picker("Músculo principal", selection: $primaryMuscle) {
                        ForEach(MuscleGroup.allCases, id: \.self) { m in
                            Text(m.displayName).tag(m)
                        }
                    }

                    Picker("Tipo", selection: $exerciseType) {
                        ForEach(ExerciseType.allCases, id: \.self) { t in
                            Text(t.displayName).tag(t)
                        }
                    }

                    Picker("Equipamiento", selection: $equipment) {
                        ForEach(Equipment.allCases, id: \.self) { e in
                            Text(e.displayName).tag(e)
                        }
                    }
                }

                Section("Músculos secundarios (opcional)") {
                    ForEach(MuscleGroup.allCases.filter { $0 != primaryMuscle }, id: \.self) { muscle in
                        HStack {
                            Text(muscle.displayName)
                            Spacer()
                            if secondaryMuscles.contains(muscle) {
                                Image(systemName: "checkmark").foregroundStyle(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if secondaryMuscles.contains(muscle) {
                                secondaryMuscles.remove(muscle)
                            } else {
                                secondaryMuscles.insert(muscle)
                            }
                        }
                    }
                }

                Section("Instrucciones (opcional)") {
                    TextEditor(text: $instructions)
                        .frame(minHeight: 100)
                }

                Section("GIF de demostración (opcional)") {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label(gifURL == nil ? "Seleccionar imagen/GIF" : "Cambiar imagen", systemImage: "photo.badge.plus")
                    }
                    if gifURL != nil {
                        Text("Imagen seleccionada")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
            }
            .navigationTitle("Ejercicio personalizado")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Guardar") { saveExercise() }
                        .fontWeight(.semibold)
                        .disabled(!canSave || isSaving)
                }
            }
        }
    }

    private func saveExercise() {
        isSaving = true
        let exercise = Exercise(
            name: name.trimmingCharacters(in: .whitespaces),
            primaryMuscleGroup: primaryMuscle,
            secondaryMuscleGroups: Array(secondaryMuscles),
            equipmentRequired: equipment,
            exerciseType: exerciseType,
            instructions: instructions,
            gifURL: gifURL,
            isCustom: true
        )
        modelContext.insert(exercise)
        try? modelContext.save()
        dismiss()
    }
}
