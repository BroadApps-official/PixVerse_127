import Foundation
import Combine

struct EffectSection: Identifiable {
    let id = UUID()
    let title: String
    let effects: [Effect]
}

class HomeViewModel: ObservableObject {
    @Published var sections: [EffectSection] = []
    @Published var trendEffect: Effect?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func loadEffects() {
        isLoading = true
        APIService.shared.fetchTemplatesByCategories(appName: "com.dmyver.skp1l3n", ai: ["pika", "pv"]) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let categories):
                    let newSections = categories
                        .filter { $0.categoryTitleEn != "Hug and Kiss" }
                        .map { category in
                            EffectSection(
                                title: category.categoryTitleEn,
                                effects: category.templates.map { template in
                                    Effect(
                                        id: String(template.id),
                                        title: template.title ?? template.effect ?? "No name",
                                        imageUrl: template.previewSmall ?? template.preview ?? "trend1",
                                        category: EffectCategory(rawValue: category.categoryTitleEn ?? "") ?? .unknown
                                    )
                                }
                            )
                        }
                    self?.sections = newSections
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
}

class HistoryViewModel: ObservableObject {
    static let shared = HistoryViewModel()
    @Published var items: [HistoryItem] = []
    private let storageKey = "history_items"
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        load()
        $items
            .sink { [weak self] _ in
                self?.save()
            }
            .store(in: &cancellables)
    }
    
    func add(item: HistoryItem) {
        items.insert(item, at: 0)
    }
    
    func updateStatus(id: String, status: HistoryStatus, resultUrl: String?) {
        if let idx = items.firstIndex(where: { $0.id == id }) {
            items[idx].status = status
            items[idx].resultUrl = resultUrl
            save()
        }
    }
    
    func remove(_ item: HistoryItem) {
        // Удаление локального файла, если есть
        if let urlString = item.resultUrl, let url = URL(string: urlString), url.isFileURL {
            try? FileManager.default.removeItem(at: url)
        }
        if let idx = items.firstIndex(where: { $0.id == item.id }) {
            items.remove(at: idx)
            save()
        }
    }
    
    private func save() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    private func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode([HistoryItem].self, from: data) {
            self.items = saved
        }
    }
    
    func logHistory() {
        print("[HistoryViewModel] Текущее содержимое истории:")
        for item in items {
            print("id: \(item.id), status: \(item.status.rawValue), resultUrl: \(item.resultUrl ?? "nil"), prompt: \(item.prompt ?? "nil"), type: \(item.type.rawValue)")
        }
    }
} 
 