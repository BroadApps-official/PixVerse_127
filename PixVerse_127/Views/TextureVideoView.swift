import SwiftUI
import AsyncDisplayKit

struct TextureVideoView: UIViewRepresentable {
    let urlString: String
    let height: CGFloat
    
    func makeUIView(context: Context) -> ASDisplayNodeView {
        let node = ASVideoNode()
        node.shouldAutoplay = true
        node.shouldAutorepeat = true
        node.muted = true
        node.backgroundColor = UIColor(white: 0.2, alpha: 1)
        node.cornerRadius = 16
        node.clipsToBounds = true
        node.gravity = AVLayerVideoGravity.resizeAspectFill.rawValue
        node.placeholderColor = UIColor(white: 0.2, alpha: 1)
        node.placeholderEnabled = true
        node.placeholderFadeDuration = 0.15
        node.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: height)
        node.isUserInteractionEnabled = false
        node.view.isUserInteractionEnabled = false
        if let url = URL(string: urlString) {
            if let cached = VideoCacheManager.shared.getCachedURL(for: url) {
                node.asset = AVAsset(url: cached)
            } else {
                VideoCacheManager.shared.downloadAndCache(url: url) { local in
                    DispatchQueue.main.async {
                        if let local = local {
                            node.asset = AVAsset(url: local)
                        }
                    }
                }
            }
        }
        return node.view
    }
    func updateUIView(_ uiView: ASDisplayNodeView, context: Context) {}
}

typealias ASDisplayNodeView = UIView

struct TextureVideoViewContainer: View {
    let urlString: String
    let height: CGFloat
    var body: some View {
        TextureVideoView(urlString: urlString, height: height)
            .allowsHitTesting(false)
    }
} 
