import Foundation
import UIKit

final class PhotoAPIService {
    static let shared = PhotoAPIService()
    private let baseURL = "https://bot.fotobudka.online/api/v1/"
    private let token = "f113066f-2ad6-43eb-b860-8683fde1042a"
    
    private let stylesCacheKey = "photo_styles_cache"
    private let stylesCacheDateKey = "photo_styles_cache_date"
    private let cacheLifetime: TimeInterval = 600 

    func fetchStylesWithCache(completion: @escaping (Result<[StyleCategory], Error>) -> Void) {
        if let data = UserDefaults.standard.data(forKey: stylesCacheKey),
           let date = UserDefaults.standard.object(forKey: stylesCacheDateKey) as? Date,
           Date().timeIntervalSince(date) < cacheLifetime {
            do {
                let decoded = try JSONDecoder().decode([StyleCategory].self, from: data)
                completion(.success(decoded))
            } catch {
            }
        }
        fetchStyles { result in
            switch result {
            case .success(let categories):
                // Сохраняем в кэш
                if let encoded = try? JSONEncoder().encode(categories) {
                    UserDefaults.standard.set(encoded, forKey: self.stylesCacheKey)
                    UserDefaults.standard.set(Date(), forKey: self.stylesCacheDateKey)
                }
                completion(.success(categories))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    // MARK: - Обычная загрузка стилей (без кэша)
    func fetchStyles(completion: @escaping (Result<[StyleCategory], Error>) -> Void) {
        let url = URL(string: baseURL + "photo/styles")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: 0)))
                return
            }
            do {
                let decoded = try JSONDecoder().decode(PhotoStylesResponse.self, from: data)
                completion(.success(decoded.data))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    func generatePhoto(imageData: Data, styleId: Int, userId: String, completion: @escaping (Result<String, Error>) -> Void) {
        let url = URL(string: baseURL + "photo/generate")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let appId = Bundle.main.bundleIdentifier ?? "com.tet.P1x2n4"
        let userIDs = "ios-test-user-11"
        var body = Data()
        func appendFormField(_ name: String, value: String) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        appendFormField("templateId", value: "\(styleId)")
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        appendFormField("userId", value: userIDs)
        appendFormField("appId", value: appId)
        // убрать
        appendFormField("avatarId", value: "40150")
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        print("[PhotoAPIService] generatePhoto URL: \(url)")
        print("[PhotoAPIService] styleId: \(styleId), userId: \("ios-test-user-1121"), appId: \(appId)")
        print("[PhotoAPIService] imageData size: \(imageData.count) bytes, type: image/jpeg")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("[PhotoAPIService] generatePhoto error: \(error)")
                completion(.failure(error))
                return
            }
            guard let data = data else {
                print("[PhotoAPIService] generatePhoto: No data")
                completion(.failure(NSError(domain: "No data", code: -1)))
                return
            }
            if let jsonData = String(data: data, encoding: .utf8) {
                print("[PhotoAPIService] Raw JSON: \(jsonData)")
            }
            do {
                let decodedResponse = try JSONDecoder().decode(Generate.self, from: data)
                if let data = decodedResponse.data, let jobId = data.jobId ?? data.generationId {
                    print("[PhotoAPIService] Success, jobId: \(jobId)")
                    completion(.success(jobId))
                } else {
                    let msg = decodedResponse.message ?? "No jobId in response data"
                    print("[PhotoAPIService] Error: \(msg)")
                    completion(.failure(NSError(domain: "NetworkingError", code: 0, userInfo: [NSLocalizedDescriptionKey: msg])))
                }
            } catch {
                print("[PhotoAPIService] Ошибка декодирования JSON: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }

    func checkGenerationStatus(userId: String, jobId: String, completion: @escaping (Result<Status, Error>) -> Void) {
        var urlComponents = URLComponents(string: baseURL + "services/status")!
        urlComponents.queryItems = [
            URLQueryItem(name: "userId", value: "ios-test-user-1121"),
            URLQueryItem(name: "jobId", value: jobId)
        ]
        guard let url = urlComponents.url else {
            print("[PhotoAPIService] checkGenerationStatus: Invalid URL")
            completion(.failure(NSError(domain: "Invalid URL", code: 0)))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        print("[PhotoAPIService] checkGenerationStatus URL: \(url)")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("[PhotoAPIService] checkGenerationStatus error: \(error)")
                completion(.failure(error))
                return
            }
            guard let data = data else {
                print("[PhotoAPIService] checkGenerationStatus: No data")
                completion(.failure(NSError(domain: "No data", code: 0)))
                return
            }
            if let jsonData = String(data: data, encoding: .utf8) {
                print("[PhotoAPIService] Raw JSON Data for checkGenerationStatus (jobId: \(jobId)): \(jsonData)")
            }
            do {
                let statusResponse = try JSONDecoder().decode(Status.self, from: data)
                print("[PhotoAPIService] checkGenerationStatus decoded: \(statusResponse)")
                completion(.success(statusResponse))
            } catch {
                print("[PhotoAPIService] Ошибка декодирования JSON для checkGenerationStatus: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }

    // MARK: - Генерация фото по тексту
    func generatePhotoFromText(userId: String, prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
        let textToBaseUrl = "https://bot.fotobudka.online/api/v1/"
        let endpoint = "photo/generate/txt2img"
        let url = URL(string: textToBaseUrl + endpoint)!
        let token = "f113066f-2ad6-43eb-b860-8683fde1042a"

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "userId", value: "ios-test-user-11"),
            URLQueryItem(name: "prompt", value: prompt)
        ]
        request.httpBody = components.query?.data(using: .utf8)
        
        print("[PhotoAPIService] generatePhotoFromText URL: \(url)")
        print("[PhotoAPIService] generatePhotoFromText prompt: \(prompt)")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("[PhotoAPIService] generatePhotoFromText error: \(error)")
                completion(.failure(error))
                return
            }
            guard let data = data else {
                print("[PhotoAPIService] generatePhotoFromText: No data")
                completion(.failure(NSError(domain: "No data", code: -1)))
                return
            }
            if let jsonData = String(data: data, encoding: .utf8) {
                print("[PhotoAPIService] Raw JSON for generatePhotoFromText: \(jsonData)")
            }
            do {
                let decodedResponse = try JSONDecoder().decode(PromptGenerateResponse.self, from: data)
                if let data = decodedResponse.data, let jobId = data.jobId {
                    print("[PhotoAPIService] Success, jobId from text: \(jobId)")
                    completion(.success(jobId))
                } else {
                    let msg = decodedResponse.message ?? "No jobId in response data"
                    print("[PhotoAPIService] Error: \(msg)")
                    completion(.failure(NSError(domain: "NetworkingError", code: 0, userInfo: [NSLocalizedDescriptionKey: msg])))
                }
            } catch {
                print("[PhotoAPIService] Ошибка декодирования JSON для generatePhotoFromText: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }
}

// MARK: - Модели для фото (актуальные)

struct PhotoStylesResponse: Codable {
    let error: Bool
    let message: String?
    let data: [StyleCategory]
}

struct StyleCategory: Codable {
    let id: Int
    let title: String?
    let preview: String?
    let isNew: Bool
    let isCouple: Bool
    let isGirlfriends: Bool
    let groupPreview: GroupPreview
    let previewByGender: PreviewByGender
    let totalTemplates: Int
    let totalUsed: Int
    let templates: [Template]
    let subCategories: [SubCategory]
}

struct GroupPreview: Codable {
    let group1: [String]
    let group2: [String]
    let group3: [String]
    enum CodingKeys: String, CodingKey {
        case group1 = "gorup1"
        case group2 = "gorup2"
        case group3 = "gorup3"
    }
}

struct PreviewByGender: Codable {
    let female: GenderGroup
    let male: GenderGroup
    enum CodingKeys: String, CodingKey {
        case female = "f"
        case male = "m"
    }
}

struct GenderGroup: Codable {
    let group1: [String]
    let group2: [String]
    let group3: [String]
}

struct SubCategory: Codable {
    let id: Int
    let title: String?
    let preview: String?
    let isNew: Bool
    let isCouple: Bool
    let isGirlfriends: Bool
    let groupPreview: GroupPreview
    let previewByGender: PreviewByGender
    let totalTemplates: Int
    let totalUsed: Int
    let templates: [Template]
}

struct Template: Codable, Identifiable {
    let id: Int
    let title: String?
    let preview: String
    let previewProduction: String
    let gender: String?
    let prompt: String?
    let isEnabled: Bool
}

struct Generate: Codable {
    let error: Bool
    let messages: [String]?
    let data: DataGenerate?
    let message: String?
}

struct DataGenerate: Codable {
    let id: Int?
    let generationId: String?
    let jobId: String?
    let totalWeekGenerations: Int?
    let maxGenerations: Int?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(Int.self, forKey: .id)
        jobId = try container.decodeIfPresent(String.self, forKey: .jobId)
        totalWeekGenerations = try container.decodeIfPresent(Int.self, forKey: .totalWeekGenerations)
        maxGenerations = try container.decodeIfPresent(Int.self, forKey: .maxGenerations)
        if let generationIdString = try? container.decodeIfPresent(String.self, forKey: .generationId) {
            generationId = generationIdString
        } else {
            if let generationIdInt = try? container.decodeIfPresent(Int.self, forKey: .generationId) {
                generationId = String(generationIdInt)
            } else {
                generationId = nil
            }
        }
    }
    enum CodingKeys: String, CodingKey {
        case id
        case generationId
        case jobId
        case totalWeekGenerations
        case maxGenerations
    }
}

struct Status: Codable {
    let error: Bool
    let messages: [String]?
    let data: StatusData?
}

struct StatusData: Codable {
    let status: String?
    let error: String?
    let resultUrl: String?
    let progress: Int?
    let totalWeekGenerations: Int?
    let maxGenerations: Int?
}

// MARK: - Модели для генерации по тексту
struct PromptGenerateResponse: Codable {
    let error: Bool
    let message: String?
    let data: PromptDataGenerate?
}

struct PromptDataGenerate: Codable {
    let jobId: String?
} 
