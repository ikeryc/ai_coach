import SwiftUI
import SwiftData
import Charts

struct BodyWeightView: View {

    @Query(sort: \BodyWeightLog.date) private var logs: [BodyWeightLog]
    @Query private var profiles: [UserProfile]

    @State private var viewModel = BodyWeightViewModel()
    @State private var showAddEntry = false
    @State private var selectedRange: ChartRange = .month

    private var userProfile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if logs.isEmpty {
                        emptyState
                    } else {
                        statsCards
                        weightChart
                        recentLogs
                    }
                }
                .padding(.horizontal)
                .padding(.top)
            }
            .navigationTitle("Peso corporal")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddEntry = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Task { await viewModel.syncFromHealthKit(modelContext: modelContext, userProfile: userProfile) }
                    } label: {
                        if viewModel.isLoadingHealthKit {
                            ProgressView().scaleEffect(0.8)
                        } else {
                            Image(systemName: "heart.fill")
                                .foregroundStyle(.red)
                        }
                    }
                    .disabled(viewModel.isLoadingHealthKit)
                }
            }
            .sheet(isPresented: $showAddEntry) {
                AddWeightEntryView(userProfile: userProfile)
            }
        }
    }

    @Environment(\.modelContext) private var modelContext

    // MARK: - Tarjetas de estadísticas

    private var statsCards: some View {
        HStack(spacing: 12) {
            let avg7d = viewModel.sevenDayAverage(from: logs)
            let change = viewModel.weeklyChange(from: logs)

            StatCard(
                title: "Media 7 días",
                value: avg7d.map { String(format: "%.1f kg", $0) } ?? "--",
                icon: "chart.bar.fill",
                color: .blue
            )

            StatCard(
                title: "Cambio semanal",
                value: change.map { (v) -> String in
                    let sign = v >= 0 ? "+" : ""
                    return "\(sign)\(String(format: "%.2f", v)) kg"
                } ?? "--",
                icon: change.map { $0 >= 0 ? "arrow.up.right" : "arrow.down.right" } ?? "minus",
                color: changeColor(change)
            )

            if let last = logs.last {
                StatCard(
                    title: "Último registro",
                    value: String(format: "%.1f kg", last.weightKg),
                    icon: "scalemass.fill",
                    color: .purple
                )
            }
        }
    }

    private func changeColor(_ change: Double?) -> Color {
        guard let change else { return .secondary }
        guard let goal = userProfile?.primaryGoal else { return .blue }
        switch goal {
        case .hypertrophy, .strength: return change > 0 ? .green : .orange
        case .fatLoss: return change < 0 ? .green : .orange
        case .recomposition: return abs(change) < 0.2 ? .green : .orange
        }
    }

    // MARK: - Gráfico

    private var weightChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Evolución del peso")
                    .font(.headline)
                Spacer()
                Picker("Rango", selection: $selectedRange) {
                    ForEach(ChartRange.allCases, id: \.self) { range in
                        Text(range.label).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
            }

            let filteredLogs = logsForRange(selectedRange)
            let movingAvg = viewModel.movingAverage(from: filteredLogs)

            Chart {
                // Puntos individuales
                ForEach(filteredLogs) { log in
                    PointMark(
                        x: .value("Fecha", log.date, unit: .day),
                        y: .value("Peso", log.weightKg)
                    )
                    .foregroundStyle(Color.blue.opacity(0.4))
                    .symbolSize(30)
                }

                // Media móvil 7 días
                ForEach(movingAvg) { point in
                    LineMark(
                        x: .value("Fecha", point.date, unit: .day),
                        y: .value("Media", point.weight)
                    )
                    .foregroundStyle(Color.blue)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: selectedRange.strideCount)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.day().month())
                }
            }
            .chartYScale(domain: .automatic(includesZero: false))
            .frame(height: 220)

            // Leyenda
            HStack(spacing: 16) {
                LegendItem(color: .blue.opacity(0.4), symbol: "circle.fill", label: "Registro diario")
                LegendItem(color: .blue, symbol: "minus", label: "Media 7 días")
            }
            .font(.caption)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Lista de registros recientes

    private var recentLogs: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Registros recientes")
                .font(.headline)

            ForEach(logs.suffix(10).reversed()) { log in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(log.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.subheadline)
                        if !log.notes.isEmpty {
                            Text(log.notes)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        Text(String(format: "%.1f kg", log.weightKg))
                            .font(.subheadline.weight(.semibold))
                        if log.source == .healthKit {
                            Image(systemName: "heart.fill")
                                .font(.caption2)
                                .foregroundStyle(.red)
                        }
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        viewModel.deleteEntry(log, modelContext: modelContext)
                    } label: {
                        Label("Eliminar", systemImage: "trash")
                    }
                }
            }
        }
    }

    // MARK: - Estado vacío

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Sin registros de peso", systemImage: "scalemass")
        } description: {
            Text("Añade tu peso diario con el botón + o sincroniza desde Apple Health.")
        } actions: {
            Button("Añadir peso") { showAddEntry = true }
                .buttonStyle(.borderedProminent)
        }
        .padding(.top, 60)
    }

    // MARK: - Helpers

    private func logsForRange(_ range: ChartRange) -> [BodyWeightLog] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -range.days, to: .now) ?? .now
        return logs.filter { $0.date >= cutoff }
    }
}

// MARK: - Enums y helpers

enum ChartRange: String, CaseIterable {
    case month = "1M"
    case threeMonths = "3M"
    case sixMonths = "6M"

    var label: String { rawValue }
    var days: Int {
        switch self { case .month: 30; case .threeMonths: 90; case .sixMonths: 180 }
    }
    var strideCount: Int {
        switch self { case .month: 7; case .threeMonths: 14; case .sixMonths: 30 }
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(color)
            Text(value)
                .font(.subheadline.bold())
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct LegendItem: View {
    let color: Color
    let symbol: String
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: symbol).foregroundStyle(color)
            Text(label).foregroundStyle(.secondary)
        }
    }
}
