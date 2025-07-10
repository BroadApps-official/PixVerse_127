import Foundation
import AVFoundation

class VideoCacheManager {
    static let shared = VideoCacheManager()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    private init() {
        cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("VideoCache")
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
    }
    
    func getCachedURL(for remoteURL: URL) -> URL? {
        let localURL = cacheDirectory.appendingPathComponent(remoteURL.lastPathComponent)
        return fileManager.fileExists(atPath: localURL.path) ? localURL : nil
    }
    
    func downloadAndCache(url: URL, completion: @escaping (URL?) -> Void) {
        let localURL = cacheDirectory.appendingPathComponent(url.lastPathComponent)
        if fileManager.fileExists(atPath: localURL.path) {
            completion(localURL)
            return
        }
        let task = URLSession.shared.downloadTask(with: url) { tempURL, response, error in
            guard let tempURL = tempURL, error == nil else {
                completion(nil)
                return
            }
            do {
                try self.fileManager.moveItem(at: tempURL, to: localURL)
                completion(localURL)
            } catch {
                completion(nil)
            }
        }
        task.resume()
    }
    
    func clearCache() {
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    func cacheSize() -> UInt64 {
        let files = (try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey], options: [])) ?? []
        return files.reduce(0) { $0 + UInt64((try? $1.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0) }
    }
    
    func cacheSizeString() -> String {
        let size = Double(cacheSize())
        if size > 1_000_000 {
            return String(format: "%.1f MB", size / 1_000_000)
        } else if size > 1_000 {
            return String(format: "%.1f KB", size / 1_000)
        } else {
            return "\(Int(size)) MB"
        }
    }
} 
