import Foundation
import Observation
import AuthenticationServices
import CryptoKit

@Observable
final class AuthViewModel {

    enum AuthMode {
        case signIn, signUp
    }

    var mode: AuthMode = .signIn
    var email = ""
    var password = ""
    var confirmPassword = ""
    var isLoading = false
    var errorMessage: String?

    private let supabase: SupabaseService
    var onSuccess: (() -> Void)?

    // Para Sign in with Apple
    private var currentNonce: String?

    init(supabase: SupabaseService = .shared) {
        self.supabase = supabase
    }

    var canSubmit: Bool {
        let emailValid = email.contains("@") && email.contains(".")
        let passwordValid = password.count >= 6
        if mode == .signUp {
            return emailValid && passwordValid && password == confirmPassword
        }
        return emailValid && passwordValid
    }

    // MARK: - Email Auth

    func submit() async {
        guard canSubmit else { return }
        isLoading = true
        errorMessage = nil

        do {
            switch mode {
            case .signIn:
                _ = try await supabase.signIn(email: email, password: password)
            case .signUp:
                _ = try await supabase.signUp(email: email, password: password)
            }
            await MainActor.run { onSuccess?() }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }

        await MainActor.run { isLoading = false }
    }

    // MARK: - Sign in with Apple

    func handleAppleSignIn(result: Result<ASAuthorization, Error>) async {
        isLoading = true
        errorMessage = nil

        switch result {
        case .success(let auth):
            guard
                let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                let tokenData = credential.identityToken,
                let idToken = String(data: tokenData, encoding: .utf8),
                let nonce = currentNonce
            else {
                await MainActor.run {
                    errorMessage = "No se pudo completar el inicio de sesión con Apple"
                    isLoading = false
                }
                return
            }

            do {
                _ = try await supabase.signInWithApple(idToken: idToken, nonce: nonce)
                await MainActor.run { onSuccess?() }
            } catch {
                await MainActor.run { errorMessage = error.localizedDescription }
            }

        case .failure(let error):
            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                await MainActor.run { errorMessage = error.localizedDescription }
            }
        }

        await MainActor.run { isLoading = false }
    }

    /// Genera un nonce aleatorio y lo prepara para la solicitud de Apple.
    func prepareAppleSignIn() -> ASAuthorizationAppleIDRequest {
        let nonce = randomNonceString()
        currentNonce = nonce
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.email]
        request.nonce = sha256(nonce)
        return request
    }

    // MARK: - Nonce helpers

    private func randomNonceString(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        while remainingLength > 0 {
            var randoms = [UInt8](repeating: 0, count: 16)
            SecRandomCopyBytes(kSecRandomDefault, randoms.count, &randoms)
            randoms.forEach { random in
                if remainingLength == 0 { return }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }

    private func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}
