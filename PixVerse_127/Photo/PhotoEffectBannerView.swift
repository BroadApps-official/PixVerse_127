import SwiftUI
import Kingfisher

struct PhotoEffectBannerView: View {
    let effects: [PhotoEffect]
    @State private var currentIndex: Int = 0
    let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack(alignment: .bottom) {
            if !effects.isEmpty {
                if let urlString = effects[currentIndex].preview, let url = URL(string: urlString) {
                    KFImage(url)
                        .resizable()
                        .placeholder {
                        Color.gray.opacity(0.2)
                    }
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 144)
                    .clipped()
                    .cornerRadius(16)
                    .animation(.easeInOut, value: currentIndex)
                } else {
                    Color.gray.opacity(0.2)
                        .frame(height: 144)
                        .cornerRadius(16)
                        .animation(.easeInOut, value: currentIndex)
                }
                
                HStack(spacing: 8) {
                    ForEach(effects.indices, id: \.self) { idx in
                        Circle()
                            .fill(idx == currentIndex ? Color.accentColor : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .onTapGesture {
                                withAnimation { currentIndex = idx }
                            }
                    }
                }
                .padding(.bottom, 12)
            }
        }
        .onReceive(timer) { _ in
            withAnimation {
                currentIndex = (currentIndex + 1) % effects.count
            }
        }
    }
}

