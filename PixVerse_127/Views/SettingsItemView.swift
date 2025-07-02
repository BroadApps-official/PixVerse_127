import SwiftUI

struct SettingsItemView: View {
    let item: SettingsItem
    @Binding var isToggled: Bool
    
    init(item: SettingsItem, isToggled: Binding<Bool>? = nil) {
        self.item = item
        self._isToggled = isToggled ?? .constant(item.isToggled)
    }
    
    var body: some View {
        Button(action: { item.action?() }) {
            HStack(spacing: 12) {
                Image(systemName: item.icon)
                    .font(.system(size: 20))
                    .foregroundColor(.accentColor)
                    .frame(width: 24, height: 24)
                
                Text(item.title)
                    .font(.custom("SpaceGrotesk-Light_Medium", size: 17))
                    .foregroundColor(.white)
                
                Spacer()
                
                switch item.type {
                case .toggle:
                    Toggle("", isOn: $isToggled)
                        .labelsHidden()
                        .tint(.accentColor)
                case .navigation:
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.4))
                case .button:
                    EmptyView()
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.black)
        }
        .buttonStyle(PlainButtonStyle())
    }
} 