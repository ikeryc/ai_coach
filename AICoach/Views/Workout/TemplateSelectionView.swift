import SwiftUI
import SwiftData

struct TemplateSelectionView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTemplate: ProgramTemplate?
    @State private var startDate = Date.now
    @State private var showConfirm = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(ProgramTemplatesCatalog.all) { template in
                        TemplateCard(
                            template: template,
                            isSelected: selectedTemplate?.id == template.id,
                            action: { selectedTemplate = template }
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Elegir template")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Usar template") { showConfirm = true }
                        .fontWeight(.semibold)
                        .disabled(selectedTemplate == nil)
                }
            }
            .sheet(isPresented: $showConfirm) {
                if let template = selectedTemplate {
                    TemplateConfirmView(template: template) { date in
                        let vm = ProgramViewModel()
                        _ = vm.createFromTemplate(template, startDate: date, modelContext: modelContext)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - TemplateCard

private struct TemplateCard: View {
    let template: ProgramTemplate
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(template.name)
                            .font(.headline)
                        Text(template.splitName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.blue)
                            .font(.title3)
                    }
                }

                Text(template.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 12) {
                    TemplateTag(text: "\(template.daysPerWeek) días/sem", icon: "calendar")
                    TemplateTag(text: "\(template.totalWeeks) semanas", icon: "clock")
                    TemplateTag(text: template.experienceLevel.displayName, icon: "chart.bar")
                    TemplateTag(text: template.goal.displayName, icon: "target")
                }
            }
            .padding(16)
            .background(isSelected ? Color.blue.opacity(0.07) : Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct TemplateTag: View {
    let text: String
    let icon: String

    var body: some View {
        Label(text, systemImage: icon)
            .font(.caption2)
            .foregroundStyle(.secondary)
    }
}

// MARK: - TemplateConfirmView

private struct TemplateConfirmView: View {
    let template: ProgramTemplate
    let onConfirm: (Date) -> Void

    @State private var startDate = Date.now
    @Environment(\.dismiss) private var dismiss

    var endDate: Date? {
        Calendar.current.date(byAdding: .weekOfYear, value: template.totalWeeks, to: startDate)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Programa seleccionado") {
                    LabeledContent("Nombre", value: template.name)
                    LabeledContent("Split", value: template.splitName)
                    LabeledContent("Duración", value: "\(template.totalWeeks) semanas")
                    LabeledContent("Días/semana", value: "\(template.daysPerWeek)")
                }

                Section("Inicio") {
                    DatePicker("Fecha de inicio", selection: $startDate, displayedComponents: .date)
                    if let end = endDate {
                        LabeledContent("Fecha fin estimada", value: end.formatted(date: .abbreviated, time: .omitted))
                    }
                }

                Section {
                    Text("Se creará el programa con todos los templates de ejercicios. Podrás editarlo después.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Confirmar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Atrás") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Crear programa") {
                        onConfirm(startDate)
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(.blue)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
