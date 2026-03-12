import SwiftUI
import SwiftData

struct ExercisePickerView: View {

    let onSelect: (Exercise) -> Void

    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @State private var viewModel = ExerciseLibraryViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                let filtered = viewModel.filtered(exercises)
                if filtered.isEmpty {
                    ContentUnavailableView.search(text: viewModel.searchText)
                } else {
                    List(filtered) { exercise in
                        Button {
                            onSelect(exercise)
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                ExerciseThumbnail(url: exercise.thumbnailURL.flatMap { URL(string: $0) })
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(exercise.name)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.primary)
                                    Text(exercise.primaryMuscleGroup.displayName)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.blue)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .listStyle(.plain)
                }
            }
            .searchable(text: $viewModel.searchText, prompt: "Buscar ejercicio")
            .navigationTitle("Añadir ejercicio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.showFavoritesOnly.toggle()
                    } label: {
                        Image(systemName: viewModel.showFavoritesOnly ? "heart.fill" : "heart")
                            .foregroundStyle(viewModel.showFavoritesOnly ? .red : .secondary)
                    }
                }
            }
        }
        .presentationDetents([.large])
    }
}
