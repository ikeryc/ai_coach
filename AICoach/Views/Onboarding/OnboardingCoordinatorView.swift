import SwiftUI
import SwiftData

struct OnboardingCoordinatorView: View {

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = OnboardingViewModel()
    var onComplete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Barra de progreso
            ProgressView(value: viewModel.currentStep.progress)
                .tint(.blue)
                .padding(.horizontal)
                .padding(.top, 8)

            // Indicador de paso
            Text("Paso \(viewModel.currentStep.rawValue + 1) de \(OnboardingViewModel.Step.allCases.count)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 4)

            // Vista del paso actual
            Group {
                switch viewModel.currentStep {
                case .basics:
                    OnboardingBasicsView(viewModel: viewModel)
                case .body:
                    OnboardingBodyView(viewModel: viewModel)
                case .goal:
                    OnboardingGoalView(viewModel: viewModel)
                case .lifestyle:
                    OnboardingLifestyleView(viewModel: viewModel)
                case .complete:
                    OnboardingCompleteView(viewModel: viewModel)
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing),
                removal: .move(edge: .leading)
            ))
            .id(viewModel.currentStep)

            // Botones de navegación
            navigationButtons
        }
        .onAppear {
            viewModel.onComplete = onComplete
        }
    }

    @ViewBuilder
    private var navigationButtons: some View {
        HStack(spacing: 12) {
            if viewModel.currentStep != .basics {
                Button("Atrás") {
                    viewModel.back()
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
            }

            if viewModel.currentStep == .complete {
                Button {
                    Task { await viewModel.createProfile(modelContext: modelContext) }
                } label: {
                    HStack {
                        if viewModel.isLoading { ProgressView().tint(.white) }
                        Text("Empezar")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(viewModel.isLoading)
            } else {
                Button {
                    viewModel.next()
                } label: {
                    Text("Continuar")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.canGoNext ? Color.blue : Color.gray)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(!viewModel.canGoNext)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }
}
