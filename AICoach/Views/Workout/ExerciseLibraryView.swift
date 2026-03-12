import SwiftUI
import SwiftData

struct ExerciseLibraryView: View {

    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @State private var viewModel = ExerciseLibraryViewModel()
    @State private var showFilters = false
    @State private var showCustomForm = false

    var body: some View {
        NavigationStack {
            Group {
                if exercises.isEmpty {
                    emptyState
                } else {
                    exerciseList
                }
            }
            .navigationTitle("Ejercicios")
            .searchable(text: $viewModel.searchText, prompt: "Buscar ejercicio")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    filterButton
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCustomForm = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showFilters) {
                ExerciseFilterView(viewModel: viewModel)
            }
            .sheet(isPresented: $showCustomForm) {
                CustomExerciseFormView()
            }
        }
    }

    // MARK: - Lista de ejercicios

    @ViewBuilder
    private var exerciseList: some View {
        let filtered = viewModel.filtered(exercises)

        if filtered.isEmpty {
            ContentUnavailableView.search(text: viewModel.searchText.isEmpty ? "filtros activos" : viewModel.searchText)
        } else if viewModel.searchText.isEmpty && !viewModel.hasActiveFilters {
            // Modo agrupado por músculo cuando no hay búsqueda activa
            List {
                ForEach(viewModel.grouped(exercises), id: \.key) { group in
                    Section(group.key.displayName) {
                        ForEach(group.exercises) { exercise in
                            ExerciseRow(
                                exercise: exercise,
                                isFavorite: viewModel.isFavorite(exercise),
                                onToggleFavorite: { viewModel.toggleFavorite(exercise) }
                            )
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        } else {
            // Modo plano cuando hay búsqueda/filtros
            List(filtered) { exercise in
                ExerciseRow(
                    exercise: exercise,
                    isFavorite: viewModel.isFavorite(exercise),
                    onToggleFavorite: { viewModel.toggleFavorite(exercise) }
                )
            }
            .listStyle(.insetGrouped)
        }
    }

    // MARK: - Estados vacíos

    private var emptyState: some View {
        ContentUnavailableView(
            "Sin ejercicios",
            systemImage: "dumbbell",
            description: Text("La biblioteca se carga al iniciar la app.\nPuedes añadir ejercicios personalizados con el botón +.")
        )
    }

    // MARK: - Botón de filtros

    private var filterButton: some View {
        Button {
            showFilters = true
        } label: {
            Label("Filtrar", systemImage: viewModel.hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                .foregroundStyle(viewModel.hasActiveFilters ? .blue : .primary)
        }
    }
}

// MARK: - Fila de ejercicio

struct ExerciseRow: View {

    let exercise: Exercise
    let isFavorite: Bool
    let onToggleFavorite: () -> Void

    var body: some View {
        NavigationLink {
            ExerciseDetailView(exercise: exercise)
        } label: {
            HStack(spacing: 12) {
                // Thumbnail
                ExerciseThumbnail(url: exercise.thumbnailURL.flatMap { URL(string: $0) })

                VStack(alignment: .leading, spacing: 3) {
                    Text(exercise.name)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        MuscleChip(muscle: exercise.primaryMuscleGroup)

                        if exercise.exerciseType == .compound {
                            Text("Compuesto")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.15))
                                .foregroundStyle(.orange)
                                .clipShape(Capsule())
                        }

                        if exercise.isCustom {
                            Text("Custom")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.purple.opacity(0.15))
                                .foregroundStyle(.purple)
                                .clipShape(Capsule())
                        }
                    }
                }

                Spacer()

                Button(action: onToggleFavorite) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(isFavorite ? .red : .secondary)
                        .font(.subheadline)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Thumbnail pequeño

struct ExerciseThumbnail: View {
    let url: URL?

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
            default:
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 44, height: 44)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Chip de músculo

struct MuscleChip: View {
    let muscle: MuscleGroup

    var body: some View {
        Text(muscle.displayName)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.blue.opacity(0.12))
            .foregroundStyle(.blue)
            .clipShape(Capsule())
    }
}
