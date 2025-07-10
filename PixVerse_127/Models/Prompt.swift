import Foundation

struct Prompt: Identifiable, Hashable {
    let id: UUID = UUID()
    let title: String
    let subtitle: String
    let iconName: String
    let category: PromptCategory
}

enum PromptCategory: String, CaseIterable, Identifiable {
    case trending = "Trending"
    case creative = "Creative"
    case productivity = "Productivity"
    case education = "Education"
    case fun = "Fun"
    
    var id: String { rawValue }
} 