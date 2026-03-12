import SwiftUI

struct ExerciseDetailView: View {

    let exercise: Exercise
    @State private var viewModel = ExerciseLibraryViewModel()
    @State private var showAllInstructions = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // GIF animado
                GIFImageView(
                    url: exercise.gifURL.flatMap { URL(string: $0) },
                    size: CGSize(width: UIScreen.main.bounds.width - 32, height: 280)
                )
                .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 20) {

                    // Nombre y tipo
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(exercise.name)
                                .font(.title2.bold())
                            Spacer()
                            Button {
                                viewModel.toggleFavorite(exercise)
                            } label: {
                                Image(systemName: viewModel.isFavorite(exercise) ? "heart.fill" : "heart")
                                    .font(.title3)
                                    .foregroundStyle(viewModel.isFavorite(exercise) ? .red : .secondary)
                            }
                        }

                        HStack(spacing: 8) {
                            Label(exercise.exerciseType.displayName, systemImage: "bolt")
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.orange.opacity(0.12))
                                .foregroundStyle(.orange)
                                .clipShape(Capsule())

                            Label(exercise.equipmentRequired.displayName, systemImage: "dumbbell")
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.gray.opacity(0.12))
                                .foregroundStyle(.secondary)
                                .clipShape(Capsule())
                        }
                    }

                    // Músculos
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Músculos trabajados")
                            .font(.headline)

                        HStack(spacing: 8) {
                            MuscleTag(
                                name: exercise.primaryMuscleGroup.displayName,
                                isPrimary: true
                            )
                            ForEach(exercise.secondaryMuscleGroups, id: \.self) { muscle in
                                MuscleTag(name: muscle.displayName, isPrimary: false)
                            }
                        }
                        .flexibleWrapping()
                    }

                    // Volumen de referencia (MEV/MAV)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Rangos de volumen semanales")
                            .font(.headline)

                        let muscle = exercise.primaryMuscleGroup
                        HStack(spacing: 12) {
                            VolumeRangeCard(label: "MEV", value: "\(muscle.mev)", subtitle: "mín. efectivo")
                            VolumeRangeCard(label: "MAV", value: "\(muscle.mav)", subtitle: "máx. adaptativo")
                            VolumeRangeCard(label: "MRV", value: "\(muscle.mrv)", subtitle: "máx. recuperable")
                        }
                    }

                    // Instrucciones
                    if !exercise.instructions.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Instrucciones")
                                .font(.headline)

                            let text = exercise.instructions
                            let isLong = text.count > 300

                            Text(showAllInstructions || !isLong ? text : String(text.prefix(300)) + "...")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)

                            if isLong {
                                Button(showAllInstructions ? "Ver menos" : "Ver más") {
                                    showAllInstructions.toggle()
                                }
                                .font(.subheadline)
                                .foregroundStyle(.blue)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 32)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Subviews

private struct MuscleTag: View {
    let name: String
    let isPrimary: Bool

    var body: some View {
        Text(name)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(isPrimary ? Color.blue.opacity(0.15) : Color(.secondarySystemGroupedBackground))
            .foregroundStyle(isPrimary ? .blue : .secondary)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(isPrimary ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
            )
    }
}

private struct VolumeRangeCard: View {
    let label: String
    let value: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.bold())
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Flexible wrap layout helper

private struct FlexibleWrappingLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

extension View {
    func flexibleWrapping() -> some View {
        FlexibleWrappingLayout { self }
    }
}
