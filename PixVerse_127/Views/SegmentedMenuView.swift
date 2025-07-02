import SwiftUI

enum HomeTab {
    case effects
    case prompt
}

struct SegmentedMenuView: View {
    @Binding var selectedTab: HomeTab
    
    var body: some View {
        HStack(spacing: 8) {
            segmentButton(
                title: "Effects",
                icon: "sparkles.square.filled.on.square",
                isSelected: selectedTab == .effects
            ) {
                withAnimation(.easeInOut) {
                    selectedTab = .effects
                }
            }
            
            segmentButton(
                title: "Prompt",
                icon: "highlighter",
                isSelected: selectedTab == .prompt
            ) {
                withAnimation(.easeInOut) {
                    selectedTab = .prompt
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    private func segmentButton(
        title: String,
        icon: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 13))
                    .kerning(-0.08)
                    .foregroundColor(isSelected ? .white : .customSecondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background {
                if isSelected {
                    LinearGradient(
                        gradient: Gradient(colors: [Color(hex: "#7A1DF2"), Color(hex: "#F2315F")]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                } else {
                    Color.segmentUnselectedBackground
                }
            }
            .cornerRadius(12)
        }
    }
}
