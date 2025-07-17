import SwiftUI

struct SubscriptionPlanRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let badge: String?
    let isSelected: Bool
    let generationLabel: String?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.white : Color.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 12, height: 12)
                    }
                }
                // Иконка (можно скрыть, если не нужна)
                // Image(systemName: icon)
                //     .font(.system(size: 17, weight: .regular))
                //     .foregroundColor(isSelected ? Color.white : Color.white.opacity(0.6))
                //     .animation(.easeInOut(duration: 0.2), value: isSelected)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 17, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? .white : Color.white.opacity(0.8))
                    if let generationLabel = generationLabel {
                        Text(generationLabel)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(isSelected ? .white : Color.white.opacity(0.7))
                    }
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(isSelected ? Color.white.opacity(0.8) : Color.white.opacity(0.5))
                }
                Spacer()
            }
            .padding(.vertical, 16)
            .padding(.leading, 12)
            .padding(.trailing, badge != nil && isSelected ? 60 : 28)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "#7A1DF2"), Color(hex: "#F2315F")]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    } else {
                        Color(hex: "#232325")
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isSelected ?
                        LinearGradient(
                            gradient: Gradient(colors: [Color.white.opacity(0.7), Color.white.opacity(0.3)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ) :
                        LinearGradient(
                            gradient: Gradient(colors: [Color.clear, Color.clear]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 2
                    )
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
