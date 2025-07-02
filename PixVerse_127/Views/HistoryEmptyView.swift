import SwiftUI

struct HistoryEmptyView: View {
    var onCreate: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("No generations")
                    .font(Font.custom("SpaceGrotesk-Light", size: 20).weight(.medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                Text("Create your first generation using effects or a text query")
                    .font(Font.custom("SpaceGrotesk-Light", size: 13))
                    .foregroundColor(Color.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            Image("history_empty")
                .resizable()
                .scaledToFit()
                .frame(width: 290, height: 200)
                .padding(.top, 32)
            
            Button(action: { onCreate?() }) {
                HStack(spacing: 8) {
                    ZStack {
                        Image(systemName: "sparkles")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.black)
                    }
                    Text("Create")
                        .font(Font.custom("SpaceGrotesk-Light", size: 17).weight(.semibold))
                        .foregroundColor(.black)
                }
                .frame(height: 48)
                .frame(maxWidth: .infinity)
                .background(Color(hex: "#D1FE17"))
                .cornerRadius(12)
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 135)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
    }
}

struct HistoryEmptyView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryEmptyView()
            .background(Color.black)
            .previewLayout(.sizeThatFits)
    }
} 
