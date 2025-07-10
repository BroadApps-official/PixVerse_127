import SwiftUI

struct PromptCardView: View {
    let prompt: Prompt
    var onCopy: (() -> Void)?
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.accentColor.opacity(0.13))
                    .frame(width: 44, height: 44)
                Image(systemName: prompt.iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .foregroundColor(.accentColor)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(prompt.title)
                    .font(.system(size: 16))
                    .foregroundColor(.black)
                    .kerning(0.1)
                Text(prompt.subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.black.opacity(0.6))
                    .kerning(0.05)
            }
            Spacer()
            Button(action: { onCopy?() }) {
                Image(systemName: "doc.on.doc")
                    .foregroundColor(.black.opacity(0.7))
                    .frame(width: 24, height: 24)
                    .padding(8)
                    .background(Color.accentColor.opacity(0.13))
                    .clipShape(Circle())
            }
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 18)
        .background(Color.white)
        .cornerRadius(22)
        .shadow(color: Color.black.opacity(0.07), radius: 16, x: 0, y: 6)
        .frame(width: 260)
    }
}

struct PromptCardView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack { Color.black
            PromptCardView(prompt: Prompt(title: "Make a viral TikTok", subtitle: "Get ideas for trending videos", iconName: "sparkles", category: .trending))
                .padding()
        }
        .previewLayout(.sizeThatFits)
    }
} 
