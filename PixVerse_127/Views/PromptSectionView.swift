import SwiftUI

struct PromptSectionView: View {
    let title: String
    let prompts: [Prompt]
    var onCopy: ((Prompt) -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3.bold())
                .foregroundColor(.primary)
                .padding(.horizontal, 4)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(prompts) { prompt in
                        PromptCardView(prompt: prompt) {
                            onCopy?(prompt)
                        }
                        .frame(width: 220)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(.vertical, 8)
    }
}

struct PromptSectionView_Previews: PreviewProvider {
    static var previews: some View {
        PromptSectionView(
            title: "Trending",
            prompts: [
                Prompt(title: "Make a viral TikTok", subtitle: "Get ideas for trending videos", iconName: "sparkles", category: .trending),
                Prompt(title: "Write a poem", subtitle: "Creative writing inspiration", iconName: "pencil", category: .creative)
            ]
        ) { _ in }
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 