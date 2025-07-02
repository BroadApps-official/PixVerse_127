import SwiftUI
import Kingfisher

struct PhotoEffectCardView: View {
    let effect: PhotoEffect
    let isSelected: Bool
    
    var body: some View {
            ZStack(alignment: .bottomLeading) {
            if let preview = effect.preview, let url = URL(string: preview) {
                KFImage(url)
                    .resizable()
                    .placeholder {
                        Color.gray.opacity(0.2)
                    }
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 140, height: 249)
                    .clipped()
                    .cornerRadius(8)
                } else {
                    Color.gray.opacity(0.2)
                        .frame(width: 140, height: 249)
                        .cornerRadius(8)
                }
                LinearGradient(
                    gradient: Gradient(colors: [.clear, .black.opacity(0.8)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 60)
                Text(effect.effect)
                    .font(.custom("SpaceGrotesk-Light_Medium", size: 15))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
            }
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
    }
} 