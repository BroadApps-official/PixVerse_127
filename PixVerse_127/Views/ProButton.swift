import SwiftUI

struct ProButton: View {
    var onTap: (() -> Void)? = nil
    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 4) {
                Text("PRO")
                    .font(.system(size: 16))
                    .kerning(-0.31)
                    .foregroundColor(.white)
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 17))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 14)
            .frame(height: 32)
            .background(LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#7A1DF2"), Color(hex: "#F62053")]),
                startPoint: .leading,
                endPoint: .trailing
            ))
            .cornerRadius(12)
        }
    }
}

struct ProButtons: View {
    var tokens: Int
    var onTap: (() -> Void)? = nil
    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 8) {
                Text("\(tokens)")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                Image(systemName: "sparkles")
                    .font(.system(size: 17))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 14)
            .frame(height: 32)
            .background( LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#7A1DF2"), Color(hex: "#F2315F")]),
                startPoint: .leading,
                endPoint: .trailing
            ))
            .cornerRadius(12)
        }
    }
}

#Preview {
    ZStack {
        Color.black
        ProButton()
    }
} 
