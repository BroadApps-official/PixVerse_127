import SwiftUI

struct SubscriptionPlanRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let badge: String?
    let isSelected: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack(spacing: 12) {
                ZStack {
                    Image(systemName: icon)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(isSelected ? Color(hex: "#9D3AE9") : Color.white.opacity(0.4))
                        .animation(.easeInOut(duration: 0.2), value: isSelected)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(isSelected ? .system(size: 17, weight: .semibold) : .system(size: 17, weight: .regular))
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(isSelected ? Color.white.opacity(0.8) : Color.white.opacity(0.4))
                }
                Spacer()
            }
            .padding(.vertical, 14)
            .padding(.leading, 12)
            .padding(.trailing, badge != nil && isSelected ? 60 : 28)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color(hex: "#232325") : Color(hex: "#1D1D1F"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
//                    .stroke(isSelected ? LinearGradient(
//                        gradient: Gradient(colors: [Color(hex: "#7A1DF2"), Color(hex: "#F2315F")]),
//                        startPoint: .leading,
//                        endPoint: .trailing
//                    ) : Color.clear, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .animation(.easeInOut(duration: 0.2), value: isSelected)
            if let badge = badge, isSelected {
                Text(badge)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 12)
                    .background(Color(hex: "#F62053"))
                    .clipShape(RoundedCorner(radius: 12, corners: [.topRight]))
                    .clipShape(RoundedCorner(radius: 12, corners: [.bottomLeft]))
                    .offset(x: -2, y: 2)
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
            }
        }
        .padding(.horizontal, 0)
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = 12.0
    var corners: UIRectCorner = .allCorners
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
    
}

#Preview {
    SubscriptionSheet(viewModel: SubscriptionViewModel())
}
