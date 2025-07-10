import Foundation

class PromptViewModel: ObservableObject {
    @Published var prompts: [Prompt] = []
    @Published var selectedCategory: PromptCategory = .trending
    
    init() {
        loadMockPrompts()
    }
    
    var filteredPrompts: [Prompt] {
        prompts.filter { $0.category == selectedCategory }
    }
    
    private func loadMockPrompts() {
        prompts = [
            Prompt(title: "Make a viral TikTok", subtitle: "Get ideas for trending videos", iconName: "sparkles", category: .trending),
            Prompt(title: "Write a poem", subtitle: "Creative writing inspiration", iconName: "pencil", category: .creative),
            Prompt(title: "Summarize text", subtitle: "Quickly get the gist", iconName: "doc.text", category: .productivity),
            Prompt(title: "Explain a concept", subtitle: "Learn something new", iconName: "book", category: .education),
            Prompt(title: "Tell a joke", subtitle: "Lighten the mood", iconName: "face.smiling", category: .fun)
        ]
    }
} 