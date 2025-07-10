import Foundation

struct PhotoHistoryItem: Codable, Identifiable {
    let id: String 
    let templateId: Int
    let templateTitle: String?
    let previewUrl: String?
    let resultUrl: String?
    let date: Date
    let status: String
} 
