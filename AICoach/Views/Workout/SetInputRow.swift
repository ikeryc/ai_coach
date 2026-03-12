import SwiftUI

struct SetInputRow: View {

    @Binding var set: ActiveSet
    let onComplete: () -> Void
    let onDelete: () -> Void

    @FocusState private var focusedField: Field?

    enum Field { case weight, reps, rir }

    var body: some View {
        HStack(spacing: 0) {
            // Número de set / warmup badge
            Button {
                set.isWarmup.toggle()
            } label: {
                Text(set.isWarmup ? "W" : "\(set.setNumber)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(set.isWarmup ? .orange : (set.isCompleted ? .white : .secondary))
                    .frame(width: 28, height: 28)
                    .background(
                        Circle().fill(
                            set.isCompleted ? Color.green :
                            set.isWarmup ? Color.orange.opacity(0.2) :
                            Color(.tertiarySystemFill)
                        )
                    )
            }
            .buttonStyle(.plain)
            .frame(width: 36, alignment: .center)

            // Anterior
            VStack(spacing: 1) {
                if let pw = set.previousWeight, let pr = set.previousReps {
                    Text("\(String(format: "%.1f", pw)) × \(pr)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("—")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)

            // Peso
            TextField("kg", value: $set.weightKg, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .focused($focusedField, equals: .weight)
                .font(.subheadline.weight(set.isCompleted ? .semibold : .regular))
                .foregroundStyle(set.isCompleted ? .primary : .secondary)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(focusedField == .weight ? Color.blue.opacity(0.1) : Color(.tertiarySystemFill))
                )
                .frame(width: 72)
                .onSubmit { focusedField = .reps }

            // Reps
            TextField("reps", value: $set.reps, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .focused($focusedField, equals: .reps)
                .font(.subheadline.weight(set.isCompleted ? .semibold : .regular))
                .foregroundStyle(set.isCompleted ? .primary : .secondary)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(focusedField == .reps ? Color.blue.opacity(0.1) : Color(.tertiarySystemFill))
                )
                .frame(width: 56)
                .padding(.leading, 6)
                .onSubmit { focusedField = .rir }

            // RIR
            TextField("rir", value: $set.rirActual, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .focused($focusedField, equals: .rir)
                .font(.subheadline.weight(set.isCompleted ? .semibold : .regular))
                .foregroundStyle(set.isCompleted ? .primary : .secondary)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(focusedField == .rir ? Color.blue.opacity(0.1) : Color(.tertiarySystemFill))
                )
                .frame(width: 44)
                .padding(.leading, 6)

            // Botón completar / eliminar
            Button {
                if set.isCompleted {
                    set.isCompleted = false
                } else {
                    focusedField = nil
                    onComplete()
                }
            } label: {
                Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(set.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)
            .frame(width: 36, alignment: .center)
            .simultaneousGesture(
                LongPressGesture().onEnded { _ in
                    onDelete()
                }
            )
        }
        .padding(.horizontal)
        .padding(.vertical, 5)
        .background(set.isCompleted ? Color.green.opacity(0.06) : Color.clear)
        .animation(.easeInOut(duration: 0.15), value: set.isCompleted)
    }
}
