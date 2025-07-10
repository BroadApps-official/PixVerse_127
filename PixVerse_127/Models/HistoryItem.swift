import Foundation

enum HistoryStatus: String, Codable {
    case inProgress
    case finished
    case failed
}

enum HistoryType: String, Codable {
    case video
    case photo
}

struct HistoryItem: Identifiable, Codable {
    let id: String
    let date: Date
    let previewUrl: String?
    var resultUrl: String?
    var status: HistoryStatus
    var type: HistoryType
    var prompt: String? = nil
    var jobId: String? = nil
    var generationId: String? = nil
} 