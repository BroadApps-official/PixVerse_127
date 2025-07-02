import SwiftUI

struct ResultHeaderView: View {
    let title: String?
    let onBack: () -> Void
    let onMenu: (() -> Void)?
    
    var body: some View {
        ZStack(alignment: .top) {
            LinearGradient(
                gradient: Gradient(colors: [Color.black.opacity(0.5), .clear]),
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 120)
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.backward")
                        .foregroundColor(.white.opacity(0.8))
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.14))
                        .clipShape(Circle())
                }
                Spacer()
                if let title = title {
                    Text(title)
                        .font(.custom("SpaceGrotesk-Light_Medium", size: 17))
                        .foregroundColor(.white)
                }
                Spacer()
                Button(action: { onMenu?() }) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.black)
                        .frame(width: 32, height: 32)
                        .background(Color(hex: "#D1FE17"))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
        }
    }
} 