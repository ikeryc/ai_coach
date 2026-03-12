import SwiftUI
import AuthenticationServices

struct AuthView: View {

    @State private var viewModel = AuthViewModel()
    var onSuccess: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 64))
                            .foregroundStyle(.blue)

                        Text("AI Coach")
                            .font(.largeTitle.bold())

                        Text("Tu entrenador personal inteligente")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 40)

                    // Selector de modo
                    Picker("Modo", selection: $viewModel.mode) {
                        Text("Iniciar sesión").tag(AuthViewModel.AuthMode.signIn)
                        Text("Crear cuenta").tag(AuthViewModel.AuthMode.signUp)
                    }
                    .pickerStyle(.segmented)

                    // Formulario
                    VStack(spacing: 16) {
                        TextField("Correo electrónico", text: $viewModel.email)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .padding()
                            .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 12))

                        SecureField("Contraseña (mín. 6 caracteres)", text: $viewModel.password)
                            .textContentType(viewModel.mode == .signUp ? .newPassword : .password)
                            .padding()
                            .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 12))

                        if viewModel.mode == .signUp {
                            SecureField("Confirmar contraseña", text: $viewModel.confirmPassword)
                                .textContentType(.newPassword)
                                .padding()
                                .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 12))
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                    .animation(.easeInOut(duration: 0.2), value: viewModel.mode)

                    // Error
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }

                    // Botón principal
                    Button {
                        Task { await viewModel.submit() }
                    } label: {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView().tint(.white)
                            }
                            Text(viewModel.mode == .signIn ? "Iniciar sesión" : "Crear cuenta")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.canSubmit ? Color.blue : Color.gray)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(!viewModel.canSubmit || viewModel.isLoading)

                    // Separador
                    HStack {
                        Rectangle().frame(height: 1).foregroundStyle(.tertiary)
                        Text("o").font(.footnote).foregroundStyle(.secondary)
                        Rectangle().frame(height: 1).foregroundStyle(.tertiary)
                    }

                    // Sign in with Apple
                    SignInWithAppleButton(
                        viewModel.mode == .signIn ? .signIn : .signUp,
                        onRequest: { request in
                            let appleRequest = viewModel.prepareAppleSignIn()
                            request.requestedScopes = appleRequest.requestedScopes
                            request.nonce = appleRequest.nonce
                        },
                        onCompletion: { result in
                            Task { await viewModel.handleAppleSignIn(result: result) }
                        }
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            viewModel.onSuccess = onSuccess
        }
    }
}
