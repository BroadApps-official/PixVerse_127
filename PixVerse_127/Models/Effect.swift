import Foundation

struct Effect: Identifiable, Equatable {
    let id: String
    let title: String
    let imageUrl: String
    let category: EffectCategory
    var isPro: Bool = false
}

enum EffectCategory: String {
    case creative = "Creative"
    case new = "New"
    case popular = "Popular"
    case unknown
} 

struct EffectResponse: Decodable {
    let id: Int
    let ai: String?
    let pos: Int?
    let title: String?
    let categoryId: Int?
    let categoryTitleRu: String?
    let categoryTitleEn: String?
    let effect: String?
    let preview: String?
    let previewSmall: String?
    let preview2: String?
    let preview2Small: String?
    let preview3: String?
    let preview3Small: String?
}

struct EffectCategoryResponse: Decodable {
    let categoryId: Int
    let categoryTitleRu: String
    let categoryTitleEn: String
    let templates: [EffectResponse]
}

struct TemplatesByCategoriesResponse: Decodable {
    let error: Bool
    let messages: [String]
    let data: [EffectCategoryResponse]
}
