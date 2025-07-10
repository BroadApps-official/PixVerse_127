import SwiftUI
import AVFoundation

struct VideoThumbnailView: View {
    let urlString: String
    let height: CGFloat
    @State private var image: UIImage? = nil
    
    var body: some View {
        ZStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: height)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: height)
                    .onAppear {
                        generateThumbnail()
                    }
            }
        }
        .cornerRadius(16)
    }
    
    private func generateThumbnail() {
        guard let url = URL(string: urlString) else { return }
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        let time = CMTime(seconds: 1, preferredTimescale: 60)
        DispatchQueue.global().async {
            do {
                let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
                let uiImage = UIImage(cgImage: cgImage)
                DispatchQueue.main.async {
                    self.image = uiImage
                }
            } catch {
            }
        }
    }
}

