import Foundation

enum VideoResolution: String, CaseIterable {
    case p720 = "720p"
    case p1080 = "1080p"
    
    var displayName: String {
        return self.rawValue
    }
}
