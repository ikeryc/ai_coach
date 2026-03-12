import SwiftUI
import SwiftData

struct AddWeightEntryView: View {

    let userProfile: UserProfile?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var weightText = ""
    @State private var date = Date.now
    @State private var notes = ""
    @State private var isSaving = false

    @State private var viewModel = BodyWeightViewModel()

    private var weightValue: Double? {
        Double(weightText.replacingOccurrences(of: ",", with: "."))
    }

    private var isValid: Bool {
        if let w = weightValue { return w >= 30 && w <= 300 }
        return false
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(alignment: .firstTextBaseline) {
                        TextField("0.0", text: $weightText)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 52, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                        Text("kg")
                            .font(.title.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                }

                Section {
                    DatePicker("Fecha", selection: $date, in: ...Date.now, displayedComponents: .date)
                }

                Section("Notas (opcional)") {
                    TextField("Ej: en ayunas, después de entrenar...", text: $notes)
                }

                if let last = lastWeight {
                    Section {
                        HStack {
                            Text("Último registro")
                            Spacer()
                            Text(String(format: "%.1f kg", last))
                                .foregroundStyle(.secondary)
                        }
                        if let w = weightValue, w > 0 {
                            let diff = w - last
                            let sign = diff >= 0 ? "+" : ""
                            HStack {
                                Text("Diferencia")
                                Spacer()
                                Text("\(sign)\(String(format: "%.2f kg", diff))")
                                    .foregroundStyle(abs(diff) < 0.5 ? .secondary : (diff > 0 ? .orange : .green))
                            }
                        }
                    }
                }
            }
            .navigationTitle("Añadir peso")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Guardar") { save() }
                        .fontWeight(.semibold)
                        .disabled(!isValid || isSaving)
                }
            }
        }
        .presentationDetents([.medium])
    }

    @Query(sort: \BodyWeightLog.date, order: .reverse) private var logs: [BodyWeightLog]

    private var lastWeight: Double? { logs.first?.weightKg }

    private func save() {
        guard let weight = weightValue else { return }
        isSaving = true
        Task {
            await viewModel.addWeightEntry(
                weightKg: weight,
                date: date,
                notes: notes,
                modelContext: modelContext,
                userProfile: userProfile
            )
            await MainActor.run { dismiss() }
        }
    }
}
