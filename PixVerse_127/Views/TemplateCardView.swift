import SwiftUI
import Kingfisher

struct TemplateCardView: View {
    let template: Template
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .bottomLeading) {
                if let url = URL(string: template.preview) {
                    KFImage(url)
                        .resizable()
                        .placeholder {
                        Color.gray.opacity(0.2)
                                .frame(width: 175, height: 249)
                                .cornerRadius(8)
                    }
                    .aspectRatio(contentMode: .fill)
                        .frame(width: 175, height: 249)
                    .clipped()
                    .cornerRadius(8)
                } else {
                    Color.gray.opacity(0.2)
                        .frame(width: 175, height: 249)
                        .cornerRadius(8)
                }
                LinearGradient(
                    gradient: Gradient(colors: [.clear, .black.opacity(0.8)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 60)
                if let title = template.title {
                    Text(title)
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 12)
                }
            }
        }
        .frame(width: 175, height: 311)
        .cornerRadius(8)
    }
} 
