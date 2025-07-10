import Foundation
import UIKit

class APIService {
    static let shared = APIService()
    let manager = Manager.shared
    private let baseURL = "https://vewapnew.online/api"
    
    func fetchTemplatesByCategories(appName: String? = nil, ai: [String]? = nil, isNew: Bool? = nil, completion: @escaping (Result<[EffectCategoryResponse], Error>) -> Void) {
        var urlComponents = URLComponents(string: "\(baseURL)/templatesByCategories")!
        var queryItems: [URLQueryItem] = []
        if let appName = appName {
            queryItems.append(URLQueryItem(name: "appName", value: "com.tet.P1x2n4"))
        }
        if let ai = ai {
            for (index, value) in ai.enumerated() {
                queryItems.append(URLQueryItem(name: "ai[\(index)]", value: value))
            }
        }
        if let isNew = isNew {
            queryItems.append(URLQueryItem(name: "isNew", value: isNew ? "true" : "false"))
        }
        urlComponents.queryItems = queryItems.isEmpty ? nil : queryItems
        guard let url = urlComponents.url else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0)))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer rE176kzVVqjtWeGToppo4lRcbz3HRLoBrZREEvgQ8fKdWuxySCw6tv52BdLKBkZTOHWda5ISwLUVTyRoZEF0A33Xpk63lF9wTCtDxOs8XK3YArAiqIXVb7ZS4IK61TYPQMu5WqzFWwXtZc1jo8w", forHTTPHeaderField: "Authorization")
        
        print("[APIService] Request: GET \(url.absoluteString)")
        print("[APIService] Headers: \(request.allHTTPHeaderFields ?? [:])")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("[APIService] Error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                print("[APIService] Response status: \(httpResponse.statusCode)")
            }
            guard let data = data else {
                print("[APIService] No data received")
                completion(.failure(NSError(domain: "No data", code: 0)))
                return
            }
            if let jsonString = String(data: data, encoding: .utf8) {
                print("[APIService] Response JSON: \(jsonString)")
            }
            do {
                let decoded = try JSONDecoder().decode(TemplatesByCategoriesResponse.self, from: data)
                print("[APIService] Parsed categories: \(decoded.data)")
                completion(.success(decoded.data))
            } catch {
                print("[APIService] Decoding error: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }

    func generate(templateId: String, image: UIImage, userId: String, appId: String, completion: @escaping (Result<String, Error>) -> Void) {
        print("[APIService] generate: templateId=\(templateId), userId=\("F452345B-BEEC-43EA-AF96-000000000"), appId=\(appId)")
        let url = URL(string: "https://vewapnew.online/api/generate")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer rE176kzVVqjtWeGToppo4lRcbz3HRLoBrZREEvgQ8fKdWuxySCw6tv52BdLKBkZTOHWda5ISwLUVTyRoZEF0A33Xpk63lF9wTCtDxOs8XK3YArAiqIXVb7ZS4IK61TYPQMu5WqzFWwXtZc1jo8w", forHTTPHeaderField: "Authorization")
        
        let imageData = image.jpegData(compressionQuality: 0.9) ?? Data()
        var body = Data()
        
        func appendFormField(_ name: String, value: String) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        
        appendFormField("templateId", value: templateId)
        appendFormField("userId", value: manager.userId)
        appendFormField("appId", value: "com.tet.P1x2n4")
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        print("[APIService] Sending request to /generate, body size: \(body.count) bytes")
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("[APIService] Error: \(error)")
                completion(.failure(error))
                return
            }
            guard let data = data else {
                print("[APIService] No data in response")
                completion(.failure(NSError(domain: "No data", code: -1)))
                return
            }
            print("[APIService] Response: \(String(data: data, encoding: .utf8) ?? "<no utf8>")")
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                if let dataDict = json?["data"] as? [String: Any], let generationId = dataDict["generationId"] as? String {
                    print("[APIService] generationId: \(generationId)")
                    completion(.success(generationId))
                } else {
                    print("[APIService] No generationId in response")
                    completion(.failure(NSError(domain: "No generationId", code: -2)))
                }
            } catch {
                print("[APIService] Decoding error: \(error)")
                completion(.failure(error))
            }
        }
        task.resume()
    }

    func getGenerationStatus(generationId: String, completion: @escaping (Result<GenerationStatusResponse, Error>) -> Void) {
        print("[APIService] getGenerationStatus: generationId=\(generationId)")
        guard let url = URL(string: "https://vewapnew.online/api/generationStatus?generationId=\(generationId)") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer rE176kzVVqjtWeGToppo4lRcbz3HRLoBrZREEvgQ8fKdWuxySCw6tv52BdLKBkZTOHWda5ISwLUVTyRoZEF0A33Xpk63lF9wTCtDxOs8XK3YArAiqIXVb7ZS4IK61TYPQMu5WqzFWwXtZc1jo8w", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("[APIService] getGenerationStatus error: \(error)")
                completion(.failure(error))
                return
            }
            guard let data = data else {
                print("[APIService] getGenerationStatus: No data")
                completion(.failure(NSError(domain: "No data", code: -2)))
                return
            }
            if let jsonString = String(data: data, encoding: .utf8) {
                print("[APIService] getGenerationStatus response: \(jsonString)")
            }
            do {
                let decoded = try JSONDecoder().decode(GenerationStatusResponse.self, from: data)
                completion(.success(decoded))
            } catch {
                print("[APIService] getGenerationStatus decode error: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }

    func fetchAvailableGenerations(userId: String, bundleId: String, completion: @escaping (Result<Int, Error>) -> Void) {
        var urlComponents = URLComponents(string: "\(baseURL)/user")!
        urlComponents.queryItems = [
            URLQueryItem(name: "userId", value: userId),
            URLQueryItem(name: "bundleId", value: bundleId)
        ]
        guard let url = urlComponents.url else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0)))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer rE176kzVVqjtWeGToppo4lRcbz3HRLoBrZREEvgQ8fKdWuxySCw6tv52BdLKBkZTOHWda5ISwLUVTyRoZEF0A33Xpk63lF9wTCtDxOs8XK3YArAiqIXVb7ZS4IK61TYPQMu5WqzFWwXtZc1jo8w", forHTTPHeaderField: "Authorization")
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
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                if let dataDict = json?["data"] as? [String: Any], let available = dataDict["availableGenerations"] as? Int {
                    completion(.success(available))
                } else {
                    completion(.failure(NSError(domain: "No availableGenerations", code: 0)))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
} 
 

class GenerationManager {
    static let shared = GenerationManager()
    private init() {}
    
    private let baseURL = URL(string: "https://vewapnew.online/api")!
    
    func generateImg2Video(prompt: String, image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard
              let appId = Bundle.main.bundleIdentifier else {
            print("[GenerationManager] Ошибка: нет userId/appId")
            completion(.failure(NSError(domain: "App", code: 0, userInfo: [NSLocalizedDescriptionKey: "No userId/appId"])))
            return
        }
        
        let userId = Manager.shared.userId
       
        let url = baseURL.appendingPathComponent("generate/img2video")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer rE176kzVVqjtWeGToppo4lRcbz3HRLoBrZREEvgQ8fKdWuxySCw6tv52BdLKBkZTOHWda5ISwLUVTyRoZEF0A33Xpk63lF9wTCtDxOs8XK3YArAiqIXVb7ZS4IK61TYPQMu5WqzFWwXtZc1jo8w", forHTTPHeaderField: "Authorization")
        let imageData = image.jpegData(compressionQuality: 0.95) ?? Data()
        var body = Data()
        // image
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"photo.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        // promptText
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"promptText\"\r\n\r\n".data(using: .utf8)!)
        body.append(prompt.data(using: .utf8) ?? Data())
        body.append("\r\n".data(using: .utf8)!)
        // userId
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"userId\"\r\n\r\n".data(using: .utf8)!)
        body.append(userId.data(using: .utf8) ?? Data())
        body.append("\r\n".data(using: .utf8)!)
        // appId
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"appId\"\r\n\r\n".data(using: .utf8)!)
        body.append(appId.data(using: .utf8) ?? Data())
        body.append("\r\n".data(using: .utf8)!)
        // end
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        print("[GenerationManager] POST \(url)")
        print("Headers: \(request.allHTTPHeaderFields ?? [:])")
        print("multipart body: [image: \(imageData.count) bytes, promptText: \(prompt), userId: \(userId), appId: \(appId)]")
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("[GenerationManager] Ошибка запроса: \(error)")
                completion(.failure(error)); return
            }
            if let httpResponse = response as? HTTPURLResponse {
                print("[GenerationManager] Status code: \(httpResponse.statusCode)")
            }
            guard let data = data else {
                print("[GenerationManager] Нет данных в ответе")
                completion(.failure(NSError(domain: "App", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data"])));
                return
            }
            if let str = String(data: data, encoding: .utf8) {
                print("[GenerationManager] Ответ: \(str)")
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                let genId = ((json?["data"] as? [String: Any])?["generationId"] as? String)
                if let genId = genId {
                    print("[GenerationManager] generationId: \(genId)")
                    completion(.success(genId))
                } else {
                    let msg = (json?["messages"] as? [String])?.joined(separator: ", ") ?? "Unknown error"
                    print("[GenerationManager] Ошибка генерации: \(msg)")
                    completion(.failure(NSError(domain: "App", code: 0, userInfo: [NSLocalizedDescriptionKey: msg])))
                }
            } catch {
                print("[GenerationManager] Ошибка парсинга JSON: \(error)")
                completion(.failure(error))
            }
        }
        task.resume()
    }
    
    private func pollGenerationStatus(generationId: String, completion: @escaping (Result<String, Error>) -> Void) {
        var components = URLComponents(url: baseURL.appendingPathComponent("generationStatus"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "generationId", value: generationId)]
        
        guard let url = components?.url else {
            print("[GenerationManager] Ошибка формирования URL статуса")
            completion(.failure(NSError(domain: "App", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid status URL"])))
            return
        }
        print("[GenerationManager] GET \(url)")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer rE176kzVVqjtWeGToppo4lRcbz3HRLoBrZREEvgQ8fKdWuxySCw6tv52BdLKBkZTOHWda5ISwLUVTyRoZEF0A33Xpk63lF9wTCtDxOs8XK3YArAiqIXVb7ZS4IK61TYPQMu5WqzFWwXtZc1jo8w", forHTTPHeaderField: "Authorization")
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("[GenerationManager] Ошибка статуса: \(error)")
                completion(.failure(error)); return
            }
            if let httpResponse = response as? HTTPURLResponse {
                print("[GenerationManager] Status code: \(httpResponse.statusCode)")
            }
            guard let data = data else {
                print("[GenerationManager] Нет данных в ответе статуса")
                completion(.failure(NSError(domain: "App", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data"])));
                return
            }
            if let str = String(data: data, encoding: .utf8) {
                print("[GenerationManager] Ответ статуса: \(str)")
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                let dataObj = json?["data"] as? [String: Any]
                let status = dataObj?["status"] as? String
                if status == "finished", let url = dataObj?["resultUrl"] as? String {
                    print("[GenerationManager] Генерация завершена, resultUrl: \(url)")
                    completion(.success(url))
                } else if let errorMsg = dataObj?["error"] as? String, !errorMsg.isEmpty {
                    print("[GenerationManager] Ошибка генерации: \(errorMsg)")
                    completion(.failure(NSError(domain: "App", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMsg])))
                } else {
                    print("[GenerationManager] Статус: \(status ?? "unknown"), повторный пуллинг через 10 сек")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                        self.pollGenerationStatus(generationId: generationId, completion: completion)
                    }
                }
            } catch {
                print("[GenerationManager] Ошибка парсинга JSON статуса: \(error)")
                completion(.failure(error))
            }
        }
        task.resume()
    }
    
    func getGenerationStatus(generationId: String, completion: @escaping (Result<GenerationStatusResponse, Error>) -> Void) {
        var components = URLComponents(url: baseURL.appendingPathComponent("generationStatus"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "generationId", value: generationId)]
        guard let url = components?.url else {
            completion(.failure(NSError(domain: "App", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid status URL"])))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer rE176kzVVqjtWeGToppo4lRcbz3HRLoBrZREEvgQ8fKdWuxySCw6tv52BdLKBkZTOHWda5ISwLUVTyRoZEF0A33Xpk63lF9wTCtDxOs8XK3YArAiqIXVb7ZS4IK61TYPQMu5WqzFWwXtZc1jo8w", forHTTPHeaderField: "Authorization")
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error)); return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "App", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data"])));
                return
            }
            do {
                let decoded = try JSONDecoder().decode(GenerationStatusResponse.self, from: data)
                completion(.success(decoded))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
}

private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

final class PhotoHistoryManager {
    static let shared = PhotoHistoryManager()
    private let key = "photo_history_items"
    
    func load() -> [PhotoHistoryItem] {
        guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([PhotoHistoryItem].self, from: data)) ?? []
    }
    
    func save(_ items: [PhotoHistoryItem]) {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    func add(_ item: PhotoHistoryItem) {
        var items = load()
        items.insert(item, at: 0)
        save(items)
    }
    
    func update(_ item: PhotoHistoryItem) {
        var items = load()
        if let idx = items.firstIndex(where: { $0.id == item.id }) {
            items[idx] = item
            save(items)
        }
    }
    
    func logHistory() {
        let items = load()
        print("[PhotoHistoryManager] Текущее содержимое истории:")
        for item in items {
            print("id: \(item.id), status: \(item.status), resultUrl: \(item.resultUrl ?? "nil"), templateTitle: \(item.templateTitle ?? "nil")")
        }
    }
}

struct GenerationStatusResponse: Decodable {
    struct DataObj: Decodable {
        let status: String?
        let error: String?
        let resultUrl: String?
    }
    let error: Bool
    let messages: [String]
    let data: DataObj?
}
