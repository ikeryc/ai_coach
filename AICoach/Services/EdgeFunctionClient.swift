import Foundation

/// Proxy para llamar a Supabase Edge Functions.
/// La API key de Claude NUNCA sale del servidor — todo pasa por Edge Functions.
final class EdgeFunctionClient {

    static let shared = EdgeFunctionClient()

    private let supabase: SupabaseService
    private let baseURL: String
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init(supabase: SupabaseService = .shared) {
        self.supabase = supabase
        self.baseURL = Constants.API.supabaseURL
    }

    // MARK: - Llamada genérica

    func call<Request: Encodable, Response: Decodable>(
        function name: String,
        payload: Request
    ) async throws -> Response {
        guard let token = supabase.session?.accessToken else {
            throw SupabaseError.notAuthenticated
        }
        guard let url = URL(string: "\(baseURL)/functions/v1/\(name)") else {
            throw SupabaseError.invalidURL
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(Constants.API.supabaseAnonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.httpBody = try encoder.encode(payload)

        let (data, response) = try await URLSession.shared.data(for: req)

        if let httpResponse = response as? HTTPURLResponse,
           !(200..<300).contains(httpResponse.statusCode) {
            let message = (try? JSONDecoder().decode([String: String].self, from: data))?["error"] ?? "Error desconocido"
            throw SupabaseError.httpError(statusCode: httpResponse.statusCode, message: message)
        }

        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw SupabaseError.decodingError(error.localizedDescription)
        }
    }

    // MARK: - Funciones específicas (se expanden en fases 6-8)

    /// Genera un programa de entrenamiento con Claude Opus via Edge Function.
    func generateTrainingProgram(context: ProgramGenerationRequest) async throws -> ProgramGenerationResponse {
        try await call(function: "generate-program", payload: context)
    }

    /// Envía un mensaje al entrenador IA con contexto completo.
    func sendChatMessage(payload: ChatMessageRequest) async throws -> ChatMessageResponse {
        try await call(function: "ai-chat", payload: payload)
    }

    /// Corre el análisis semanal y devuelve sugerencias de adaptación.
    func runWeeklyAnalysis(userId: String) async throws -> WeeklyAnalysisResponse {
        try await call(function: "weekly-analysis", payload: ["user_id": userId])
    }
}

// MARK: - Request / Response types

struct ProgramGenerationRequest: Encodable {
    let userId: String
    let contextJSON: String
}

/// Contexto serializado que se envía a la Edge Function para generar el programa.
struct ProgramGenerationContext: Encodable {
    let goal: String
    let experienceLevel: String
    let availableDays: Int
    let equipment: String
    let language: String = "es"
}

// MARK: - Generated program parsing

/// DTO que representa el JSON que devuelve Claude con el programa generado.
struct GeneratedProgramDTO: Decodable {
    let name: String
    let totalWeeks: Int
    let days: [DayDTO]

    struct DayDTO: Decodable {
        let dayOfWeek: Int
        let name: String
        let exercises: [ExerciseDTO]
    }

    struct ExerciseDTO: Decodable {
        let exerciseName: String
        let sets: Int
        let repMin: Int
        let repMax: Int
        let rir: Int
        let restSeconds: Int?
    }
}

struct ProgramGenerationResponse: Decodable {
    let programJSON: String
    let explanation: String
}

struct ChatMessageRequest: Encodable {
    let conversationId: String
    let userMessage: String
    let contextJSON: String
}

struct ChatMessageResponse: Decodable {
    let assistantMessage: String
    let tokensUsed: Int?
}

struct WeeklyAnalysisResponse: Decodable {
    let suggestions: [AdaptationSuggestion]
}

struct AdaptationSuggestion: Decodable, Identifiable {
    let id: String
    let type: String
    let reason: String
    let previousValue: String?
    let newValue: String?
}
