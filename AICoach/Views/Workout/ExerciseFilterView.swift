import SwiftUI

struct ExerciseFilterView: View {

    @Bindable var viewModel: ExerciseLibraryViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                // Grupo muscular
                Section("Grupo muscular") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(
                                title: "Todos",
                                isSelected: viewModel.selectedMuscle == nil,
                                action: { viewModel.selectedMuscle = nil }
                            )
                            ForEach(MuscleGroup.allCases, id: \.self) { muscle in
                                FilterChip(
                                    title: muscle.displayName,
                                    isSelected: viewModel.selectedMuscle == muscle,
                                    action: { viewModel.selectedMuscle = muscle }
                                )
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }

                // Equipamiento
                Section("Equipamiento") {
                    ForEach(Equipment.allCases, id: \.self) { eq in
                        HStack {
                            Text(eq.displayName)
                            Spacer()
                            if viewModel.selectedEquipment == eq {
                                Image(systemName: "checkmark").foregroundStyle(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.selectedEquipment = viewModel.selectedEquipment == eq ? nil : eq
                        }
                    }
                }

                // Tipo de ejercicio
                Section("Tipo") {
                    ForEach(ExerciseType.allCases, id: \.self) { type in
                        HStack {
                            Text(type.displayName)
                            Spacer()
                            if viewModel.selectedType == type {
                                Image(systemName: "checkmark").foregroundStyle(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.selectedType = viewModel.selectedType == type ? nil : type
                        }
                    }
                }

                // Favoritos
                Section {
                    Toggle("Solo favoritos", isOn: $viewModel.showFavoritesOnly)
                }
            }
            .navigationTitle("Filtros")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Limpiar") {
                        viewModel.clearFilters()
                    }
                    .foregroundStyle(.red)
                    .disabled(!viewModel.hasActiveFilters)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Aplicar") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - FilterChip

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? Color.blue : Color(.secondarySystemGroupedBackground))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
