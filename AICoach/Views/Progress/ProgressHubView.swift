import SwiftUI

struct ProgressHubView: View {

    @State private var section = 0

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $section) {
                Text("Peso").tag(0)
                Text("Fuerza").tag(1)
                Text("Volumen").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemGroupedBackground))

            Divider()

            Group {
                switch section {
                case 0: BodyWeightView()
                case 1: StrengthProgressView()
                default: VolumeChartView()
                }
            }
            .id(section)
        }
    }
}
