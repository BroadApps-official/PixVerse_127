import SwiftUI
import PhotosUI

class PhotoEffectDetailViewModel: ObservableObject {
    @Published var selectedPhotoItem: PhotosPickerItem? {
        didSet {
            if let item = selectedPhotoItem {
                loadImage(from: item)
            }
        }
    }
    
    @Published var isGenerating = false
    @Published var generationStatus: String?
    @Published var resultUrl: String?
    @Published var showError = false
    @Published var errorMessage = ""
    
    @Published var showFirstTimeHint: Bool = false
    
    private var pollTimer: Timer?
    private var currentTemplate: Template?
    
    init() {
        showFirstTimeHint = !UserDefaults.standard.bool(forKey: "PhotoEffectDetailView_HintShown")
    }
    
    func hideFirstTimeHint() {
        showFirstTimeHint = false
        UserDefaults.standard.set(true, forKey: "PhotoEffectDetailView_HintShown")
    }
    
    func setTemplate(_ template: Template) {
        self.currentTemplate = template
    }

    private func loadImage(from item: PhotosPickerItem) {
        item.loadTransferable(type: Data.self) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    if let data, let image = UIImage(data: data) {
                        if let template = self.currentTemplate {
                            self.startGeneration(template: template, image: image)
                        }
                    } else {
                        self.errorMessage = "Failed to load image"
                        self.showError = true
                    }
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                }
            }
        }
    }
    
    private func startGeneration(template: Template, image: UIImage) {
        isGenerating = true
        generationStatus = "Uploading image..."
        
        let historyItem = PhotoHistoryItem(
            id: UUID().uuidString,
            templateId: template.id,
            templateTitle: template.title,
            previewUrl: template.preview,
            resultUrl: nil,
            date: Date(),
            status: "pending"
        )
        PhotoHistoryManager.shared.add(historyItem)
        let history = HistoryItem(
            id: historyItem.id,
            date: historyItem.date,
            previewUrl: historyItem.previewUrl,
            resultUrl: nil,
            status: .inProgress,
            type: .photo,
            prompt: nil,
            jobId: nil,
            generationId: nil
        )
        HistoryViewModel.shared.add(item: history)
        
        guard let imageData = image.jpegData(compressionQuality: 0.9) else {
            isGenerating = false
            errorMessage = "Could not process image."
            showError = true
            return
        }
        
        PhotoAPIService.shared.generatePhoto(imageData: imageData, styleId: template.id, userId: "ios-test-user-1121") { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let jobId):
                    self.pollStatus(jobId: jobId, historyItem: historyItem)
                case .failure(let error):
                    self.isGenerating = false
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                }
            }
        }
    }
    
    private func pollStatus(jobId: String, historyItem: PhotoHistoryItem) {
        generationStatus = "Generating image..."
        pollTimer?.invalidate()
        
        pollTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] timer in
            PhotoAPIService.shared.checkGenerationStatus(userId: "ios-test-user-1121", jobId: jobId) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let statusResponse):
                        if let data = statusResponse.data {
                            self?.generationStatus = "Status: \(data.status ?? "...") (\(data.progress ?? 0)%)"
                            let status = data.status?.lowercased()
                            
                            if status == "completed" || status == "succeeded" || status == "ok" {
                                if let url = data.resultUrl {
                                    self?.isGenerating = false
                                    self?.resultUrl = url
                                    let finishedItem = PhotoHistoryItem(id: historyItem.id, templateId: historyItem.templateId, templateTitle: historyItem.templateTitle, previewUrl: historyItem.previewUrl, resultUrl: url, date: historyItem.date, status: "finished")
                                    PhotoHistoryManager.shared.update(finishedItem)
                                    HistoryViewModel.shared.updateStatus(id: historyItem.id, status: .finished, resultUrl: url)
                                    timer.invalidate()
                                }
                            } else if status == "failed" || status == "error" {
                                self?.isGenerating = false
                                self?.errorMessage = data.error ?? "Generation failed"
                                self?.showError = true
                                let failedItem = PhotoHistoryItem(id: historyItem.id, templateId: historyItem.templateId, templateTitle: historyItem.templateTitle, previewUrl: historyItem.previewUrl, resultUrl: nil, date: historyItem.date, status: "failed")
                                PhotoHistoryManager.shared.update(failedItem)
                                HistoryViewModel.shared.updateStatus(id: historyItem.id, status: .failed, resultUrl: nil)
                                timer.invalidate()
                            }
                        }
                    case .failure(let error):
                        self?.isGenerating = false
                        self?.errorMessage = error.localizedDescription
                        self?.showError = true
                        let failedItem = PhotoHistoryItem(id: historyItem.id, templateId: historyItem.templateId, templateTitle: historyItem.templateTitle, previewUrl: historyItem.previewUrl, resultUrl: nil, date: historyItem.date, status: "failed")
                        PhotoHistoryManager.shared.update(failedItem)
                        HistoryViewModel.shared.updateStatus(id: historyItem.id, status: .failed, resultUrl: nil)
                        timer.invalidate()
                    }
                }
            }
        }
    }
    
    deinit {
        pollTimer?.invalidate()
    }
} 
