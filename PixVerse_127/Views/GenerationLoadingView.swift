import SwiftUI
import Lottie

struct GenerationLoadingView: View {
    var onClose: (() -> Void)? = nil
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 36) {
                Spacer()
                Text("Loading")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                LottieView(animation: .named("HiggsfieldApp.json"))
                    .playing(loopMode: .autoReverse)
                    .frame(width: 300, height: 300)
                    .padding()
                
                Spacer()
                Text("Generation usually takes about a minute. You can close this screen, the generation will go to «History».")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
                Spacer()
            }
            if let onClose = onClose {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: { onClose() }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.white)
                                .font(.system(size: 20, weight: .bold))
                                .frame(width: 36, height: 36)
                                .background(Circle().fill(.gray))
                                .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 2)
                        }
                        .padding(.top, 12)
                        .padding(.trailing, 12)
                    }
                    Spacer()
                    
                }
            }
        }
    }
}

struct GenerationLoadingView_Previews: PreviewProvider {
    static var previews: some View {
        GenerationLoadingView()
    }
}
