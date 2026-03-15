import SwiftUI
import AVFoundation

/// UIViewRepresentable que activa la cámara y detecta códigos de barras EAN/UPC.
struct BarcodeScannerView: UIViewRepresentable {

    let onScan: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black

        let session = AVCaptureSession()
        context.coordinator.session = session

        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            return view
        }
        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else { return view }
        session.addOutput(output)
        output.setMetadataObjectsDelegate(context.coordinator, queue: .main)
        output.metadataObjectTypes = [.ean8, .ean13, .upce, .code128]

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        context.coordinator.previewLayer = preview
        view.layer.addSublayer(preview)

        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.previewLayer?.frame = uiView.bounds
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.session?.stopRunning()
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        let onScan: (String) -> Void
        var session: AVCaptureSession?
        var previewLayer: AVCaptureVideoPreviewLayer?
        private var hasScanned = false

        init(onScan: @escaping (String) -> Void) {
            self.onScan = onScan
        }

        func metadataOutput(
            _ output: AVCaptureMetadataOutput,
            didOutput metadataObjects: [AVMetadataObject],
            from connection: AVCaptureConnection
        ) {
            guard !hasScanned,
                  let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                  let code = obj.stringValue else { return }
            hasScanned = true
            session?.stopRunning()
            onScan(code)
        }
    }
}

// MARK: - Full scanner sheet

struct BarcodeScannerSheet: View {

    let onScan: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var permissionDenied = false

    var body: some View {
        NavigationStack {
            ZStack {
                if permissionDenied {
                    permissionDeniedView
                } else {
                    BarcodeScannerView { code in
                        onScan(code)
                        dismiss()
                    }
                    .ignoresSafeArea()

                    // Overlay: viewfinder guide
                    VStack {
                        Spacer()
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.8), lineWidth: 2)
                            .frame(width: 260, height: 140)
                        Text("Apunta al código de barras")
                            .font(.caption)
                            .foregroundStyle(.white)
                            .padding(.top, 12)
                        Spacer()
                    }
                }
            }
            .navigationTitle("Escanear código")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task { await checkPermission() }
        }
    }

    private var permissionDeniedView: some View {
        ContentUnavailableView {
            Label("Cámara no disponible", systemImage: "camera.fill")
        } description: {
            Text("Activa el acceso a la cámara en Ajustes > AI Coach.")
        } actions: {
            Button("Abrir Ajustes") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func checkPermission() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: break
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            if !granted { permissionDenied = true }
        default:
            permissionDenied = true
        }
    }
}
