import SwiftUI

struct SegmentedControl: View {
    let segments: [String]
    @Binding var selected: String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(segments, id: \.self) { segment in
                    Button(action: {
                        withAnimation(.easeInOut) {
                            selected = segment
                        }
                    }) {
                        Text(segment)
                            .font(.custom("SpaceGrotesk-Light_Medium", size: 13))
                            .foregroundColor(selected == segment ? .black : .white.opacity(0.4))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(selected == segment ? Color.accentColor : Color.white.opacity(0.1))
                            .cornerRadius(40)
                            .overlay(
                                RoundedRectangle(cornerRadius: 40)
                                    .stroke(selected == segment ? Color.accentColor : Color.white.opacity(0.24), lineWidth: 1)
                            )
                    }
                }
            }
            .padding(.horizontal)
        }
    }
} 