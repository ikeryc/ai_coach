import SwiftUI
import SwiftData

struct CoachView: View {

    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query(
        filter: #Predicate<AdaptationEvent> { !$0.userApproved },
        sort: \AdaptationEvent.appliedAt, order: .reverse
    ) private var pendingAdaptations: [AdaptationEvent]

    @State private var viewModel = ChatViewModel()
    @State private var showConversationList = false

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Adaptation strip (only when there are pending suggestions)
                if !pendingAdaptations.isEmpty {
                    adaptationStrip
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                Divider()

                // Chat messages
                chatMessagesArea

                Divider()

                // Input bar
                inputBar
            }
            .navigationTitle(viewModel.currentConversation?.title ?? "Entrenador IA")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if let p = profile {
                            viewModel.startNewConversation(profile: p, modelContext: modelContext)
                        }
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showConversationList = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                    .disabled(profile?.aiConversations.isEmpty ?? true)
                }
            }
            .sheet(isPresented: $showConversationList) {
                if let p = profile {
                    ConversationListSheet(
                        profile: p,
                        selected: viewModel.currentConversation,
                        onSelect: { viewModel.selectConversation($0) }
                    )
                }
            }
            .task {
                if let p = profile {
                    viewModel.startOrContinueConversation(profile: p, modelContext: modelContext)
                    viewModel.runAdaptationAnalysis(profile: p, modelContext: modelContext)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: pendingAdaptations.count)
        }
    }

    // MARK: - Adaptation strip

    private var adaptationStrip: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.purple)
                Text("Sugerencias del entrenador")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(pendingAdaptations.count)")
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Color.purple.opacity(0.15))
                    .foregroundStyle(.purple)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(pendingAdaptations) { event in
                        AdaptationCard(
                            event: event,
                            onApprove: {
                                if let p = profile {
                                    viewModel.approveAdaptation(event, profile: p, modelContext: modelContext)
                                }
                            },
                            onDismiss: {
                                viewModel.dismissAdaptation(event, modelContext: modelContext)
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
    }

    // MARK: - Chat messages

    private var chatMessagesArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    if viewModel.sortedMessages.isEmpty {
                        emptyConversationView
                            .padding(.top, 60)
                    } else {
                        ForEach(viewModel.sortedMessages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                        if viewModel.isSending {
                            TypingIndicator()
                                .id("typing")
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .onChange(of: viewModel.sortedMessages.count) { _, _ in
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: viewModel.isSending) { _, sending in
                if sending { scrollToBottom(proxy: proxy) }
            }
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        if viewModel.isSending {
            withAnimation { proxy.scrollTo("typing", anchor: .bottom) }
        } else if let last = viewModel.sortedMessages.last {
            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
        }
    }

    private var emptyConversationView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 52))
                .foregroundStyle(.secondary)
            Text("¿En qué puedo ayudarte?")
                .font(.title3.weight(.semibold))
            Text("Pregúntame sobre tu entrenamiento, nutrición, progreso o cualquier duda que tengas.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Quick starters
            VStack(spacing: 8) {
                ForEach(quickStarters, id: \.self) { starter in
                    Button {
                        viewModel.inputText = starter
                    } label: {
                        Text(starter)
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                }
            }
            .padding(.top, 8)
        }
    }

    private let quickStarters = [
        "¿Cómo voy con mi progreso esta semana?",
        "¿Debería hacer deload próximamente?",
        "¿Estoy comiendo suficiente proteína?"
    ]

    // MARK: - Input bar

    private var inputBar: some View {
        VStack(spacing: 0) {
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 16)
                    .padding(.top, 6)
            }

            HStack(alignment: .bottom, spacing: 10) {
                TextField("Escribe un mensaje...", text: $viewModel.inputText, axis: .vertical)
                    .lineLimit(1...5)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                Button {
                    if let p = profile {
                        Task { await viewModel.sendMessage(profile: p, modelContext: modelContext) }
                    }
                } label: {
                    if viewModel.isSending {
                        ProgressView()
                            .frame(width: 36, height: 36)
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(viewModel.inputText.trimmingCharacters(in: .whitespaces).isEmpty ? .secondary : .blue)
                    }
                }
                .disabled(viewModel.inputText.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isSending)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - AdaptationCard

private struct AdaptationCard: View {
    let event: AdaptationEvent
    let onApprove: () -> Void
    let onDismiss: () -> Void

    var valueChange: String {
        guard let newData = event.newValue,
              let dict = try? JSONDecoder().decode([String: Int].self, from: newData),
              let newVal = dict.values.first,
              let prevData = event.previousValue,
              let prevDict = try? JSONDecoder().decode([String: Int].self, from: prevData),
              let prevVal = prevDict.values.first else { return "" }
        let diff = newVal - prevVal
        let sign = diff >= 0 ? "+" : ""
        return "\(prevVal) → \(newVal) (\(sign)\(diff))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: event.adaptationType.systemImage)
                    .foregroundStyle(.purple)
                Text(event.adaptationType.displayName)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(event.triggeredBy.displayName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Text(event.triggerReason)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)

            if !valueChange.isEmpty {
                Text(valueChange)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.purple)
            }

            HStack(spacing: 8) {
                Button {
                    withAnimation { onApprove() }
                } label: {
                    Label("Aplicar", systemImage: "checkmark")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.purple)
                        .clipShape(Capsule())
                }

                Button {
                    withAnimation { onDismiss() }
                } label: {
                    Text("Ignorar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(.systemGray5))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(14)
        .frame(width: 280)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}

// MARK: - MessageBubble

private struct MessageBubble: View {
    let message: AIMessage

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isFromUser { Spacer(minLength: 60) }

            if !message.isFromUser {
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundStyle(.purple)
                    .frame(width: 28, height: 28)
                    .background(Color.purple.opacity(0.12))
                    .clipShape(Circle())
            }

            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.subheadline)
                    .foregroundStyle(message.isFromUser ? .white : .primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(message.isFromUser ? Color.blue : Color(.secondarySystemGroupedBackground))
                    .clipShape(BubbleShape(isFromUser: message.isFromUser))

                Text(message.createdAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if !message.isFromUser { Spacer(minLength: 60) }
        }
    }
}

// MARK: - BubbleShape

private struct BubbleShape: Shape {
    let isFromUser: Bool
    let radius: CGFloat = 18
    let tail: CGFloat = 6

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let tl = CGPoint(x: rect.minX + (isFromUser ? radius : tail), y: rect.minY)
        let tr = CGPoint(x: rect.maxX - (isFromUser ? tail : radius), y: rect.minY)
        let bl = CGPoint(x: rect.minX + (isFromUser ? radius : tail), y: rect.maxY)
        let br = CGPoint(x: rect.maxX - (isFromUser ? tail : radius), y: rect.maxY)

        path.move(to: CGPoint(x: tl.x, y: rect.minY))
        path.addLine(to: CGPoint(x: tr.x, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - (isFromUser ? tail : 0), y: rect.minY + radius),
                          control: CGPoint(x: rect.maxX - (isFromUser ? tail : 0), y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - (isFromUser ? tail : 0), y: rect.maxY - radius))
        path.addQuadCurve(to: CGPoint(x: br.x, y: rect.maxY),
                          control: CGPoint(x: rect.maxX - (isFromUser ? tail : 0), y: rect.maxY))
        path.addLine(to: CGPoint(x: bl.x, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.minX + (isFromUser ? 0 : tail), y: rect.maxY - radius),
                          control: CGPoint(x: rect.minX + (isFromUser ? 0 : tail), y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + (isFromUser ? 0 : tail), y: rect.minY + radius))
        path.addQuadCurve(to: CGPoint(x: tl.x, y: rect.minY),
                          control: CGPoint(x: rect.minX + (isFromUser ? 0 : tail), y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// MARK: - TypingIndicator

private struct TypingIndicator: View {
    @State private var phase = 0

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            Image(systemName: "sparkles")
                .font(.caption)
                .foregroundStyle(.purple)
                .frame(width: 28, height: 28)
                .background(Color.purple.opacity(0.12))
                .clipShape(Circle())

            HStack(spacing: 4) {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(Color.secondary)
                        .frame(width: 7, height: 7)
                        .scaleEffect(phase == i ? 1.3 : 0.8)
                        .animation(.easeInOut(duration: 0.4).repeatForever().delay(Double(i) * 0.15), value: phase)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18))

            Spacer(minLength: 60)
        }
        .onAppear { phase = 1 }
    }
}

// MARK: - ConversationListSheet

private struct ConversationListSheet: View {
    let profile: UserProfile
    let selected: AIConversation?
    let onSelect: (AIConversation) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private var conversations: [AIConversation] {
        profile.aiConversations.sorted { $0.updatedAt > $1.updatedAt }
    }

    var body: some View {
        NavigationStack {
            List(conversations) { conv in
                Button {
                    onSelect(conv)
                    dismiss()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(conv.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                            Text(conv.updatedAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if conv.id == selected?.id {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                                .font(.caption.weight(.bold))
                        }
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        modelContext.delete(conv)
                        try? modelContext.save()
                    } label: {
                        Label("Eliminar", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Conversaciones")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
    }
}
