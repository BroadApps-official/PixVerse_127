import SwiftUI
import PhotosUI
import Combine

class EffectsPageViewModel: ObservableObject {
    @Published var effects: [Effect]
    @Published var currentIndex: Int
    @Published var selectedPhotoItem: PhotosPickerItem? {
        didSet {
            if let item = selectedPhotoItem {
                loadImage(from: item)
            }
        }
    }
    
    @Published var isGenerating = false
    @Published var generationStatus: String? = nil
    @Published var resultUrl: String? = nil
    @Published var showError = false
    @Published var errorMessage = ""
    
    private var cancellables = Set<AnyCancellable>()

    init(effects: [Effect], currentIndex: Int) {
        self.effects = effects
        self.currentIndex = currentIndex
    }
    
    var currentEffect: Effect {
        return effects[currentIndex % effects.count]
    }

    func loadImage(from item: PhotosPickerItem) {
        print("[VM] loadImage from PhotosPickerItem: \(item)")
        item.loadTransferable(type: Data.self) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    if let data, let image = UIImage(data: data) {
                        print("[VM] Image loaded, size: \(data.count) bytes")
                        self.startGeneration(with: image)
                    } else {
                        print("[VM] Failed to decode image data")
                        self.errorMessage = "Failed to load image"
                        self.showError = true
                    }
                case .failure(let error):
                    print("[VM] Error loading image: \(error)")
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                }
            }
        }
    }
    
    func startGeneration(with image: UIImage) {
        print("[VM] startGeneration called for effect: \(currentEffect.title)")
        isGenerating = true
        generationStatus = "Generating..."
        let userId = UIDevice.current.identifierForVendor?.uuidString ?? "test-user"
        let appId = Bundle.main.bundleIdentifier ?? "com.ham.411e6t"
        let historyId = UUID().uuidString
        
        let historyItem = HistoryItem(
            id: historyId,
            date: Date(),
            previewUrl: nil,
            resultUrl: nil,
            status: .inProgress,
            type: .video,
            prompt: nil,
            jobId: nil,
            generationId: nil
        )
        HistoryViewModel.shared.add(item: historyItem)
        
        APIService.shared.generate(templateId: currentEffect.id, image: image, userId: userId, bundleId: appId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let generationId):
                    print("[VM] generationId received: \(generationId)")
                    self.pollGenerationStatus(generationId: generationId, historyId: historyId)
                case .failure(let error):
                    print("[VM] Error from generate: \(error)")
                    self.isGenerating = false
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                    HistoryViewModel.shared.updateStatus(id: historyId, status: .failed, resultUrl: nil)
                }
            }
        }
    }
    
    private func pollGenerationStatus(generationId: String, historyId: String) {
        print("[VM] pollGenerationStatus: \(generationId)")
        generationStatus = "Processing..."
        APIService.shared.getGenerationStatus(generationId: generationId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    guard let data = response.data else {
                        self.isGenerating = false
                        self.errorMessage = "Ошибка: пустой ответ сервера"
                        self.showError = true
                        HistoryViewModel.shared.updateStatus(id: historyId, status: .failed, resultUrl: nil)
                        return
                    }
                    if data.status == "finished", let resultUrl = data.resultUrl {
                        self.isGenerating = false
                        self.resultUrl = resultUrl
                        HistoryViewModel.shared.updateStatus(id: historyId, status: .finished, resultUrl: resultUrl)
                    } else if let errorText = data.error, !errorText.isEmpty {
                        self.isGenerating = false
                        self.errorMessage = errorText
                        self.showError = true
                        HistoryViewModel.shared.updateStatus(id: historyId, status: .failed, resultUrl: nil)
                    } else {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            self.pollGenerationStatus(generationId: generationId, historyId: historyId)
                        }
                    }
                case .failure(let error):
                    self.isGenerating = false
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                    HistoryViewModel.shared.updateStatus(id: historyId, status: .failed, resultUrl: nil)
                }
            }
        }
    }
} 
