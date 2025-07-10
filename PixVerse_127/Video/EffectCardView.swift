import SwiftUI
import Kingfisher

struct EffectCardView: View {
    let effect: Effect
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .bottomLeading) {
                TextureVideoViewContainer(urlString: effect.imageUrl, height: 249)
                    .frame(width: 175, height: 249)
                    .clipped()
                LinearGradient(
                    gradient: Gradient(colors: [.clear, .black.opacity(0.8)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 60)
                Text(effect.title)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
            }
        }
        .frame(width: 175, height: 311)
    }
}
