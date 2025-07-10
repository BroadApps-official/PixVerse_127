import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    static let accentColor = Color.white
    
    static let customBackground = Color.black
    static let customText = Color.white
    static let customSecondaryText = Color.white.opacity(0.4)
    static let customDivider = Color.white.opacity(0.24)
    
    static let segmentSelectedBackground = Color(hex: "D1FE17").opacity(0.12)
    static let segmentUnselectedBackground = Color.black.opacity(0.92)
    
    static let bannerGradient = LinearGradient(
        gradient: Gradient(colors: [.clear, .black.opacity(0.8)]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let cardGradient = LinearGradient(
        gradient: Gradient(colors: [.clear, Color(hex: "100F0F")]),
        startPoint: .top,
        endPoint: .bottom
    )
}
