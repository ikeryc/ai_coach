import SwiftUI

struct AddFoodEntrySheet: View {

    let mealType: MealType
    let viewModel: NutritionViewModel
    let onAdd: (FoodItemDTO, Double) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var showBarcodeScanner = false
    @State private var selectedFood: FoodItemDTO?
    @State private var quantityGrams: Double = 100
    @State private var quantityText = "100"

    var body: some View {
        NavigationStack {
            Group {
                if let food = selectedFood {
                    quantityPicker(food: food)
                } else {
                    searchView
                }
            }
            .navigationTitle("Añadir a \(mealType.displayName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(selectedFood != nil ? "Volver" : "Cancelar") {
                        if selectedFood != nil {
                            selectedFood = nil
                        } else {
                            dismiss()
                        }
                    }
                }
            }
            .sheet(isPresented: $showBarcodeScanner) {
                BarcodeScannerSheet { barcode in
                    Task {
                        if let dto = await viewModel.lookupBarcode(barcode) {
                            selectedFood = dto
                            quantityGrams = dto.servingSizeG ?? 100
                            quantityText = String(format: "%.0f", quantityGrams)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Search view

    private var searchView: some View {
        VStack(spacing: 0) {
            // Search bar + barcode button
            HStack(spacing: 10) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Buscar alimento...", text: $searchText)
                        .submitLabel(.search)
                        .onSubmit {
                            Task { await viewModel.searchFood(query: searchText) }
                        }
                    if !searchText.isEmpty {
                        Button { searchText = ""; viewModel.searchResults = [] } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(10)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10))

                Button {
                    showBarcodeScanner = true
                } label: {
                    Image(systemName: "barcode.viewfinder")
                        .font(.title3)
                        .foregroundStyle(.blue)
                        .frame(width: 44, height: 44)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding()

            if viewModel.isLoadingSearch {
                Spacer()
                ProgressView("Buscando...")
                Spacer()
            } else if let error = viewModel.searchError {
                Spacer()
                ContentUnavailableView("Sin resultados", systemImage: "magnifyingglass", description: Text(error))
                Spacer()
            } else if viewModel.searchResults.isEmpty && !searchText.isEmpty {
                Spacer()
                ContentUnavailableView(
                    "Sin resultados",
                    systemImage: "fork.knife",
                    description: Text("Prueba con otro término o escanea el código de barras.")
                )
                Spacer()
            } else if viewModel.searchResults.isEmpty {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("Busca por nombre o escanea el código de barras del producto")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                Spacer()
            } else {
                List(viewModel.searchResults) { dto in
                    Button {
                        selectedFood = dto
                        quantityGrams = dto.servingSizeG ?? 100
                        quantityText = String(format: "%.0f", quantityGrams)
                    } label: {
                        FoodSearchRow(dto: dto)
                    }
                    .buttonStyle(.plain)
                }
                .listStyle(.plain)
            }
        }
        .onChange(of: searchText) { _, newValue in
            if newValue.isEmpty { viewModel.searchResults = [] }
        }
    }

    // MARK: - Quantity picker

    private func quantityPicker(food: FoodItemDTO) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Food info card
                VStack(alignment: .leading, spacing: 8) {
                    Text(food.name)
                        .font(.headline)
                    if let brand = food.brand {
                        Text(brand)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    HStack(spacing: 16) {
                        nutrientBadge(value: food.caloriesPer100g, label: "kcal", color: .red)
                        nutrientBadge(value: food.proteinPer100g, label: "P", color: .blue)
                        nutrientBadge(value: food.carbsPer100g, label: "C", color: .orange)
                        nutrientBadge(value: food.fatPer100g, label: "G", color: .yellow)
                    }
                    Text("por 100g")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))

                // Quantity input
                VStack(alignment: .leading, spacing: 12) {
                    Text("Cantidad")
                        .font(.headline)

                    HStack {
                        TextField("Gramos", text: $quantityText)
                            .keyboardType(.decimalPad)
                            .font(.title2.weight(.semibold))
                            .multilineTextAlignment(.center)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .onChange(of: quantityText) { _, v in
                                if let parsed = Double(v.replacingOccurrences(of: ",", with: ".")) {
                                    quantityGrams = max(1, parsed)
                                }
                            }
                        Text("g")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }

                    // Quick quantity buttons
                    HStack(spacing: 10) {
                        ForEach([50.0, 100.0, 150.0, 200.0], id: \.self) { g in
                            Button {
                                quantityGrams = g
                                quantityText = String(format: "%.0f", g)
                            } label: {
                                Text("\(Int(g))g")
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(quantityGrams == g ? Color.blue : Color(.systemGray5))
                                    .foregroundStyle(quantityGrams == g ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                        }
                        if let serving = food.servingSizeG, ![50, 100, 150, 200].contains(Int(serving)) {
                            Button {
                                quantityGrams = serving
                                quantityText = String(format: "%.0f", serving)
                            } label: {
                                Text("\(Int(serving))g")
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(quantityGrams == serving ? Color.blue : Color(.systemGray5))
                                    .foregroundStyle(quantityGrams == serving ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                .padding(16)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))

                // Computed macros preview
                VStack(spacing: 8) {
                    Text("Para \(String(format: "%.0f", quantityGrams))g")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 12) {
                        macroCard(
                            value: food.caloriesPer100g * quantityGrams / 100,
                            label: "Calorías",
                            unit: "kcal",
                            color: .red
                        )
                        macroCard(
                            value: food.proteinPer100g * quantityGrams / 100,
                            label: "Proteína",
                            unit: "g",
                            color: .blue
                        )
                        macroCard(
                            value: food.carbsPer100g * quantityGrams / 100,
                            label: "Carbos",
                            unit: "g",
                            color: .orange
                        )
                        macroCard(
                            value: food.fatPer100g * quantityGrams / 100,
                            label: "Grasas",
                            unit: "g",
                            color: .yellow
                        )
                    }
                }
                .padding(16)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))

                // Confirm button
                Button {
                    onAdd(food, quantityGrams)
                    dismiss()
                } label: {
                    Text("Añadir a \(mealType.displayName)")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .disabled(quantityGrams <= 0)
            }
            .padding()
        }
    }

    // MARK: - Helpers

    private func nutrientBadge(value: Double, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(String(format: "%.0f", value))
                .font(.subheadline.weight(.bold))
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func macroCard(value: Double, label: String, unit: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(String(format: "%.0f", value))
                .font(.title3.weight(.bold))
                .foregroundStyle(color)
            Text(unit)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - FoodSearchRow

struct FoodSearchRow: View {
    let dto: FoodItemDTO

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(dto.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                if let brand = dto.brand {
                    Text(brand)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Text(dto.macroSummary)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.0f", dto.caloriesPer100g))
                    .font(.subheadline.weight(.semibold))
                Text("kcal/100g")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
