import Foundation

struct PhotoEffect: Identifiable, Decodable {
    let id: Int
    let effect: String
    let preview: String?
    var isPro: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case id, effect, preview
    }
}

enum PhotoEffectCategory: String {
    case creative = "Creative"
    case new = "New"
    case popular = "Popular"
} 
