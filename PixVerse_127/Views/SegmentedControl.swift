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
                            .font(.system(size: 13))
                            .foregroundColor(selected == segment ? .white : .white.opacity(0.4))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(selected == segment ? Color.white : .white.opacity(0.4), lineWidth: 1)
                            )
                    }
                }
            }
            .padding(.horizontal)
        }
    }
} 
