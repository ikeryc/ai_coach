import SwiftUI
import SwiftData

struct ActiveWorkoutView: View {

    @Bindable var viewModel: WorkoutSessionViewModel
    let userProfile: UserProfile?
    let onDismiss: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var elapsedDisplay = "00:00"
    @State private var showDiscardAlert = false
    @State private var showRestTimer = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Contenido principal
                ScrollView {
                    LazyVStack(spacing: 0) {
                        if viewModel.activeExercises.isEmpty {
                            emptyState
                        } else {
                            ForEach($viewModel.activeExercises) { $activeExercise in
                                ActiveExerciseSection(
                                    activeExercise: $activeExercise,
                                    viewModel: viewModel
                                ) { exerciseId, setId in
                                    viewModel.completeSet(exerciseId: exerciseId, setId: setId, modelContext: modelContext)
                                    withAnimation { showRestTimer = true }
                                }
                                Divider().padding(.leading, 16)
                            }
                        }

                        // Botón añadir ejercicio
                        Button {
                            viewModel.showExercisePicker = true
                        } label: {
                            Label("Añadir ejercicio", systemImage: "plus.circle.fill")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.secondarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                        }
                        .foregroundStyle(.blue)

                        // Espacio para el timer flotante
                        if viewModel.restTimerRunning {
                            Spacer().frame(height: 100)
                        }

                        Spacer().frame(height: 40)
                    }
                }

                // Timer de descanso flotante
                if viewModel.restTimerRunning || showRestTimer {
                    RestTimerView(viewModel: viewModel)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .onDisappear { showRestTimer = false }
                }
            }
            .navigationTitle(viewModel.sessionName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showDiscardAlert = true
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.red)
                    }
                }
                ToolbarItem(placement: .principal) {
                    // Timer en curso
                    Text(elapsedDisplay)
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.finishSession(modelContext: modelContext)
                    } label: {
                        Text("Finalizar")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.green)
                    }
                    .disabled(viewModel.totalCompletedSets == 0)
                }
            }
            .sheet(isPresented: $viewModel.showExercisePicker) {
                ExercisePickerView { exercise in
                    viewModel.addExercise(exercise, modelContext: modelContext)
                }
            }
            .sheet(isPresented: $viewModel.showSummary) {
                WorkoutSummaryView(viewModel: viewModel, onDismiss: onDismiss)
            }
            .alert("Descartar sesión", isPresented: $showDiscardAlert) {
                Button("Descartar", role: .destructive) {
                    viewModel.discardSession(modelContext: modelContext)
                    onDismiss()
                }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Se perderán todos los sets registrados en esta sesión.")
            }
        }
        .interactiveDismissDisabled()
        .task {
            // Actualiza el timer en pantalla cada segundo
            while !viewModel.isFinished {
                elapsedDisplay = viewModel.elapsedDisplay
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "dumbbell")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("Añade ejercicios para empezar")
                .font(.headline)
                .foregroundStyle(.secondary)
            Button {
                viewModel.showExercisePicker = true
            } label: {
                Label("Añadir ejercicio", systemImage: "plus")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }
}

// MARK: - Sección de ejercicio

struct ActiveExerciseSection: View {

    @Binding var activeExercise: ActiveExercise
    let viewModel: WorkoutSessionViewModel
    let onSetCompleted: (UUID, UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Cabecera del ejercicio
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(activeExercise.exercise.name)
                        .font(.headline)
                    Text(activeExercise.exercise.primaryMuscleGroup.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Menu {
                    Button {
                        viewModel.addSet(to: activeExercise.id)
                    } label: {
                        Label("Añadir set", systemImage: "plus")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)

            // Cabecera de columnas
            HStack {
                Text("SET")
                    .frame(width: 36, alignment: .center)
                Text("ANTERIOR")
                    .frame(maxWidth: .infinity, alignment: .center)
                Text("KG")
                    .frame(width: 72, alignment: .center)
                Text("REPS")
                    .frame(width: 56, alignment: .center)
                Text("RIR")
                    .frame(width: 44, alignment: .center)
                Spacer().frame(width: 36)
            }
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal)
            .padding(.bottom, 6)

            // Filas de sets
            ForEach($activeExercise.sets) { $set in
                SetInputRow(
                    set: $set,
                    onComplete: {
                        onSetCompleted(activeExercise.id, set.id)
                    },
                    onDelete: {
                        viewModel.removeSet(exerciseId: activeExercise.id, setId: set.id)
                    }
                )
            }
            .padding(.bottom, 8)
        }
        .padding(.top, 4)
    }
}
