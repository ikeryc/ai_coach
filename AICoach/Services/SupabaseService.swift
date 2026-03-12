import Foundation
import Observation

// MARK: - Session Model

struct SupabaseSession: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let tokenType: String
    let user: SupabaseUser

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
        case user
    }
}

struct SupabaseUser: Codable {
    let id: String
    let email: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case createdAt = "created_at"
    }
}

// MARK: - Errors

enum SupabaseError: LocalizedError {
    case invalidURL
    case notAuthenticated
    case httpError(statusCode: Int, message: String)
    case decodingError(String)
    case networkError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: "URL inválida"
        case .notAuthenticated: "Sesión no iniciada"
        case .httpError(let code, let msg): "Error \(code): \(msg)"
        case .decodingError(let msg): "Error de datos: \(msg)"
        case .networkError(let msg): "Error de red: \(msg)"
        }
    }
}

// MARK: - SupabaseService

@Observable
final class SupabaseService {

    static let shared = SupabaseService()

    private(set) var session: SupabaseSession?
    var isAuthenticated: Bool { session != nil }

    private let baseURL: String
    private let anonKey: String
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(
        baseURL: String = Constants.API.supabaseURL,
        anonKey: String = Constants.API.supabaseAnonKey
    ) {
        self.baseURL = baseURL
        self.anonKey = anonKey
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
        self.session = loadSessionFromKeychain()
    }

    // MARK: - Auth

    func signUp(email: String, password: String) async throws -> SupabaseSession {
        let body = ["email": email, "password": password]
        let session: SupabaseSession = try await request(
            path: "/auth/v1/signup",
            method: "POST",
            body: body,
            authenticated: false
        )
        persistSession(session)
        return session
    }

    func signIn(email: String, password: String) async throws -> SupabaseSession {
        let body = ["email": email, "password": password]
        let session: SupabaseSession = try await request(
            path: "/auth/v1/token?grant_type=password",
            method: "POST",
            body: body,
            authenticated: false
        )
        persistSession(session)
        return session
    }

    /// Sign In with Apple — intercambia el Apple identity token por una sesión Supabase.
    func signInWithApple(idToken: String, nonce: String) async throws -> SupabaseSession {
        let body: [String: String] = [
            "provider": "apple",
            "id_token": idToken,
            "nonce": nonce
        ]
        let session: SupabaseSession = try await request(
            path: "/auth/v1/token?grant_type=id_token",
            method: "POST",
            body: body,
            authenticated: false
        )
        persistSession(session)
        return session
    }

    func signOut() async throws {
        if isAuthenticated {
            try? await request(path: "/auth/v1/logout", method: "POST", body: EmptyBody(), authenticated: true) as Void
        }
        clearSession()
    }

    func refreshSession() async throws {
        guard let current = session else { throw SupabaseError.notAuthenticated }
        let body = ["refresh_token": current.refreshToken]
        let newSession: SupabaseSession = try await request(
            path: "/auth/v1/token?grant_type=refresh_token",
            method: "POST",
            body: body,
            authenticated: false
        )
        persistSession(newSession)
    }

    // MARK: - REST API (tabla → operaciones CRUD)

    func insert<T: Encodable>(_ value: T, into table: String) async throws {
        let _: EmptyResponse = try await request(
            path: "/rest/v1/\(table)",
            method: "POST",
            body: value,
            authenticated: true,
            extraHeaders: ["Prefer": "return=minimal"]
        )
    }

    func select<T: Decodable>(from table: String, filter: String? = nil) async throws -> [T] {
        var path = "/rest/v1/\(table)"
        if let filter { path += "?\(filter)" }
        return try await request(path: path, method: "GET", body: nil as EmptyBody?, authenticated: true)
    }

    func update<T: Encodable>(_ value: T, in table: String, matching filter: String) async throws {
        let _: EmptyResponse = try await request(
            path: "/rest/v1/\(table)?\(filter)",
            method: "PATCH",
            body: value,
            authenticated: true,
            extraHeaders: ["Prefer": "return=minimal"]
        )
    }

    func delete(from table: String, matching filter: String) async throws {
        let _: EmptyResponse = try await request(
            path: "/rest/v1/\(table)?\(filter)",
            method: "DELETE",
            body: nil as EmptyBody?,
            authenticated: true
        )
    }

    // MARK: - Private HTTP

    @discardableResult
    private func request<Body: Encodable, Response: Decodable>(
        path: String,
        method: String,
        body: Body?,
        authenticated: Bool,
        extraHeaders: [String: String] = [:]
    ) async throws -> Response {
        guard let url = URL(string: baseURL + path) else {
            throw SupabaseError.invalidURL
        }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(anonKey, forHTTPHeaderField: "apikey")

        if authenticated {
            guard let token = session?.accessToken else { throw SupabaseError.notAuthenticated }
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        for (key, value) in extraHeaders {
            req.setValue(value, forHTTPHeaderField: key)
        }

        if let body {
            req.httpBody = try encoder.encode(body)
        }

        let (data, response) = try await URLSession.shared.data(for: req)

        if let httpResponse = response as? HTTPURLResponse,
           !(200..<300).contains(httpResponse.statusCode) {
            let message = (try? JSONDecoder().decode([String: String].self, from: data))?["message"] ?? "Error desconocido"
            throw SupabaseError.httpError(statusCode: httpResponse.statusCode, message: message)
        }

        if Response.self == EmptyResponse.self {
            return EmptyResponse() as! Response
        }

        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw SupabaseError.decodingError(error.localizedDescription)
        }
    }

    // MARK: - Session Persistence

    private func persistSession(_ session: SupabaseSession) {
        self.session = session
        KeychainHelper.save(session.accessToken, forKey: KeychainHelper.Keys.accessToken)
        KeychainHelper.save(session.refreshToken, forKey: KeychainHelper.Keys.refreshToken)
        KeychainHelper.save(session.user.id, forKey: KeychainHelper.Keys.userId)
    }

    private func clearSession() {
        session = nil
        KeychainHelper.delete(forKey: KeychainHelper.Keys.accessToken)
        KeychainHelper.delete(forKey: KeychainHelper.Keys.refreshToken)
        KeychainHelper.delete(forKey: KeychainHelper.Keys.userId)
    }

    private func loadSessionFromKeychain() -> SupabaseSession? {
        // No podemos reconstruir la sesión completa sin los datos del usuario —
        // en el arranque llamamos a refreshSession() si hay refresh token.
        nil
    }

    /// Llama a refreshSession al iniciar la app si hay refresh token guardado.
    func restoreSessionIfNeeded() async {
        guard let refreshToken = KeychainHelper.read(forKey: KeychainHelper.Keys.refreshToken),
              !refreshToken.isEmpty else { return }
        // Construimos una sesión mínima solo para hacer el refresh
        let body = ["refresh_token": refreshToken]
        do {
            let newSession: SupabaseSession = try await request(
                path: "/auth/v1/token?grant_type=refresh_token",
                method: "POST",
                body: body,
                authenticated: false
            )
            persistSession(newSession)
        } catch {
            clearSession()
        }
    }
}

// MARK: - Helpers

private struct EmptyBody: Encodable {}
private struct EmptyResponse: Decodable {}
