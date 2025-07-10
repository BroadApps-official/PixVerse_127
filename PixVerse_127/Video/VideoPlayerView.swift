import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let urlString: String
    let height: CGFloat
    @State private var localUrl: URL? = nil
    @State private var isLoading = true
    @State private var player: AVPlayer? = nil
    
    var body: some View {
        ZStack {
            if let player = player, localUrl != nil {
                VideoPlayer(player: player)
                    .frame(height: height)
                    .cornerRadius(16)
                    .onAppear {
                        player.seek(to: .zero)
                        player.play()
                        player.isMuted = true
                        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { _ in
                            player.seek(to: .zero)
                            player.play()
                        }
                    }
            } else if isLoading {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: height)
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }
        }
        .onAppear {
            guard let url = URL(string: urlString) else { return }
            if let cached = VideoCacheManager.shared.getCachedURL(for: url) {
                localUrl = cached
                player = AVPlayer(url: cached)
                isLoading = false
            } else {
                VideoCacheManager.shared.downloadAndCache(url: url) { local in
                    DispatchQueue.main.async {
                        if let local = local {
                            localUrl = local
                            player = AVPlayer(url: local)
                        }
                        isLoading = false
                    }
                }
            }
        }
    }
} 