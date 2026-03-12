import SwiftUI

struct OnboardingBodyView: View {

    @Bindable var viewModel: OnboardingViewModel
    @State private var weightText = ""
    @State private var heightText = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                OnboardingHeader(
                    title: viewModel.currentStep.title,
                    subtitle: "Usamos estos datos para calcular tu TDEE y macros iniciales. Puedes actualizarlos en cualquier momento."
                )

                // Peso
                VStack(alignment: .leading, spacing: 12) {
                    Text("Peso corporal")
                        .font(.headline)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        TextField("75", text: $weightText)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .frame(maxWidth: 140)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: weightText) { _, new in
                                if let val = Double(new.replacingOccurrences(of: ",", with: ".")),
                                   val >= 30, val <= 300 {
                                    viewModel.weightKg = val
                                }
                            }

                        Text("kg")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 14))

                    Text("Entre 30 y 300 kg")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Altura
                VStack(alignment: .leading, spacing: 12) {
                    Text("Altura")
                        .font(.headline)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        TextField("175", text: $heightText)
                            .keyboardType(.numberPad)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .frame(maxWidth: 140)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: heightText) { _, new in
                                if let val = Double(new), val >= 100, val <= 250 {
                                    viewModel.heightCm = val
                                }
                            }

                        Text("cm")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 14))

                    Text("Entre 100 y 250 cm")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // IMC informativo
                if viewModel.weightKg > 0 && viewModel.heightCm > 0 {
                    let bmi = Formulas.bmi(weightKg: viewModel.weightKg, heightCm: viewModel.heightCm)
                    HStack {
                        Image(systemName: "info.circle")
                        Text("IMC: \(String(format: "%.1f", bmi)) — \(Formulas.bmiCategory(bmi: bmi))")
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding()
                    .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 10))
                }

                Spacer(minLength: 20)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
        }
        .onAppear {
            weightText = viewModel.weightKg == 75 ? "" : String(viewModel.weightKg)
            heightText = viewModel.heightCm == 175 ? "" : String(Int(viewModel.heightCm))
        }
    }
}
