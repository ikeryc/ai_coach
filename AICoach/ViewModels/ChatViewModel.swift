import Foundation
import SwiftData
import Observation

@Observable
final class ChatViewModel {

    var currentConversation: AIConversation?
    var isSending = false
    var errorMessage: String?
    var inputText = ""

    private let edgeClient = EdgeFunctionClient.shared

    // MARK: - Conversation management

    func startOrContinueConversation(profile: UserProfile, modelContext: ModelContext) {
        if let recent = profile.aiConversations.sorted(by: { $0.updatedAt > $1.updatedAt }).first {
            currentConversation = recent
        } else {
            startNewConversation(profile: profile, modelContext: modelContext)
        }
    }

    func startNewConversation(profile: UserProfile, modelContext: ModelContext) {
        let conv = AIConversation(title: "Nueva conversación")
        conv.userProfile = profile
        modelContext.insert(conv)
        try? modelContext.save()
        currentConversation = conv
    }

    func selectConversation(_ conv: AIConversation) {
        currentConversation = conv
    }

    var sortedMessages: [AIMessage] {
        currentConversation?.sortedMessages ?? []
    }

    // MARK: - Send message

    func sendMessage(profile: UserProfile, modelContext: ModelContext) async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isSending else { return }

        if currentConversation == nil {
            startNewConversation(profile: profile, modelContext: modelContext)
        }
        guard let conv = currentConversation else { return }

        // Add user message immediately
        let userMsg = AIMessage(role: .user, content: text)
        userMsg.conversation = conv
        modelContext.insert(userMsg)
        conv.updatedAt = .now
        try? modelContext.save()

        inputText = ""
        isSending = true
        errorMessage = nil

        do {
            let response = try await edgeClient.sendChatMessage(payload: ChatMessageRequest(
                conversationId: conv.id.uuidString,
                userMessage: text,
                contextJSON: buildContextJSON(profile: profile)
            ))

            let assistantMsg = AIMessage(
                role: .assistant,
                content: response.assistantMessage,
                tokensUsed: response.tokensUsed
            )
            assistantMsg.conversation = conv
            modelContext.insert(assistantMsg)

            // Auto-title from first user message
            if conv.messages.filter({ $0.role == .user }).count == 1 {
                conv.title = String(text.prefix(50))
            }
            conv.updatedAt = .now
            try? modelContext.save()
        } catch {
            errorMessage = error.localizedDescription
        }

        isSending = false
    }

    // MARK: - Context builder

    private func buildContextJSON(profile: UserProfile) -> String {
        var context: [String: Any] = [
            "goal": profile.primaryGoal.rawValue,
            "experience": profile.experienceLevel.rawValue,
            "weight_kg": profile.weightKg,
            "height_cm": profile.heightCm,
            "age": profile.age,
            "sex": profile.sex.rawValue
        ]

        if let prog = profile.trainingPrograms.first(where: { $0.status == .active }) {
            var progDict: [String: Any] = ["name": prog.name, "total_weeks": prog.totalWeeks]
            if let w = prog.currentWeek { progDict["current_week"] = w }
            context["active_program"] = progDict
        }

        if let m = profile.weeklyMetrics.sorted(by: { $0.weekStartDate > $1.weekStartDate }).first {
            var metricsDict: [String: Any] = [
                "sessions_completed": m.trainingSessionsCompleted,
                "sessions_planned": m.trainingSessionsPlanned,
                "adherence_pct": m.adherencePercentage
            ]
            if let w = m.avgWeight7d        { metricsDict["avg_weight_7d"] = w }
            if let c = m.weightChangeVsPrevWeek { metricsDict["weight_change_kg"] = c }
            context["latest_week"] = metricsDict
        }

        if let goal = profile.nutritionGoals
            .filter({ $0.isActive })
            .sorted(by: { $0.startDate > $1.startDate }).first {
            context["nutrition_goal"] = [
                "calories": goal.caloriesTarget,
                "protein_g": goal.proteinG,
                "carbs_g": goal.carbsG,
                "fat_g": goal.fatG
            ]
        }

        guard let data = try? JSONSerialization.data(withJSONObject: context),
              let str = String(data: data, encoding: .utf8) else { return "{}" }
        return str
    }

    // MARK: - Adaptation

    func runAdaptationAnalysis(profile: UserProfile, modelContext: ModelContext) {
        AdaptationEngine.shared.analyze(profile: profile, modelContext: modelContext)
    }

    func approveAdaptation(_ event: AdaptationEvent, profile: UserProfile, modelContext: ModelContext) {
        AdaptationEngine.shared.apply(event, profile: profile, modelContext: modelContext)
    }

    func dismissAdaptation(_ event: AdaptationEvent, modelContext: ModelContext) {
        modelContext.delete(event)
        try? modelContext.save()
    }
}
