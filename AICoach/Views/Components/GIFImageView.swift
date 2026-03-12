import SwiftUI
import UIKit
import ImageIO

/// Carga y anima un GIF desde una URL remota usando UIImageView nativo.
/// Sin dependencias externas — usa ImageIO de Apple.
struct GIFImageView: View {

    let url: URL?
    var size: CGSize = CGSize(width: 280, height: 280)

    @State private var gifData: Data?
    @State private var isLoading = true

    var body: some View {
        Group {
            if let data = gifData {
                AnimatedGIFRepresentable(data: data)
                    .frame(width: size.width, height: size.height)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else if isLoading {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
                    .frame(width: size.width, height: size.height)
                    .overlay { ProgressView() }
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
                    .frame(width: size.width, height: size.height)
                    .overlay {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 48))
                            .foregroundStyle(.tertiary)
                    }
            }
        }
        .task(id: url) {
            await loadGIF()
        }
    }

    private func loadGIF() async {
        guard let url else {
            isLoading = false
            return
        }
        isLoading = true

        // Caché simple en memoria usando URLSession
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            gifData = data
        } catch {
            // No hay GIF disponible — muestra placeholder
        }
        isLoading = false
    }
}

// MARK: - UIViewRepresentable para animar el GIF

private struct AnimatedGIFRepresentable: UIViewRepresentable {

    let data: Data

    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        return imageView
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {
        if let animatedImage = animatedImage(from: data) {
            uiView.image = animatedImage
        } else if let staticImage = UIImage(data: data) {
            uiView.image = staticImage
        }
    }

    private func animatedImage(from data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let count = CGImageSourceGetCount(source)
        guard count > 1 else { return nil }

        var frames: [UIImage] = []
        var totalDuration: Double = 0

        for i in 0..<count {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) else { continue }
            let frame = UIImage(cgImage: cgImage)
            frames.append(frame)

            let properties = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [CFString: Any]
            let gifProps = properties?[kCGImagePropertyGIFDictionary] as? [CFString: Any]
            let delay = (gifProps?[kCGImagePropertyGIFDelayTime] as? Double) ?? 0.1
            totalDuration += delay
        }

        return UIImage.animatedImage(with: frames, duration: totalDuration)
    }
}
